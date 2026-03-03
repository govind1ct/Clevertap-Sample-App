import SwiftUI
import FirebaseStorage

private enum AppAsyncImageCache {
    static let urlCache = NSCache<NSString, NSURL>()
}

struct AppAsyncImage<Content: View>: View {
    let urlString: String?
    let content: (AsyncImagePhase) -> Content

    @State private var resolvedURL: URL?

    init(urlString: String?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.urlString = urlString
        self.content = content
    }

    var body: some View {
        Group {
            if let resolvedURL {
                AsyncImage(url: resolvedURL, content: content)
            } else {
                content(.empty)
            }
        }
        .task(id: urlString ?? "") {
            resolvedURL = await resolveURL(from: urlString)
        }
    }

    private func resolveURL(from raw: String?) async -> URL? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let cached = AppAsyncImageCache.urlCache.object(forKey: trimmed as NSString) {
            return cached as URL
        }

        // Firebase Storage URL: gs://...
        if trimmed.hasPrefix("gs://") {
            do {
                let downloadURL = try await fetchFirebaseStorageDownloadURL(gsURL: trimmed)
                AppAsyncImageCache.urlCache.setObject(downloadURL as NSURL, forKey: trimmed as NSString)
                return downloadURL
            } catch {
                return nil
            }
        }

        // Direct URL first.
        if let url = URL(string: trimmed), let scheme = url.scheme, !scheme.isEmpty {
            AppAsyncImageCache.urlCache.setObject(url as NSURL, forKey: trimmed as NSString)
            return url
        }

        // Common malformed URL handling (spaces/special chars).
        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded) {
            AppAsyncImageCache.urlCache.setObject(url as NSURL, forKey: trimmed as NSString)
            return url
        }

        // Fallback for bare domains.
        if trimmed.hasPrefix("www."), let url = URL(string: "https://\(trimmed)") {
            AppAsyncImageCache.urlCache.setObject(url as NSURL, forKey: trimmed as NSString)
            return url
        }

        return nil
    }

    private func fetchFirebaseStorageDownloadURL(gsURL: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let ref = Storage.storage().reference(forURL: gsURL)
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
        }
    }
}
