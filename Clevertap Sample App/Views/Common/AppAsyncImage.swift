import SwiftUI
import FirebaseStorage

private enum AppAsyncImageCache {
    static let urlCache = NSCache<NSString, NSURL>()
    static let imageCache = NSCache<NSString, UIImage>()
}

struct AppAsyncImage<Content: View>: View {
    let urlString: String?
    let content: (AsyncImagePhase) -> Content

    @State private var resolvedURL: URL?
    @StateObject private var loader = AppAsyncImageLoader()

    init(urlString: String?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.urlString = urlString
        self.content = content
    }

    var body: some View {
        Group {
            if let image = loader.image {
                content(.success(Image(uiImage: image)))
            } else if let error = loader.error {
                content(.failure(error))
            } else {
                content(.empty)
            }
        }
        .task(id: urlString ?? "") {
            resolvedURL = await resolveURL(from: urlString)
            if let resolvedURL {
                await loader.load(url: resolvedURL)
            } else {
                loader.reset()
            }
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

@MainActor
private final class AppAsyncImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var error: Error?

    func reset() {
        image = nil
        error = nil
    }

    func load(url: URL) async {
        let cacheKey = url.absoluteString as NSString
        if let cached = AppAsyncImageCache.imageCache.object(forKey: cacheKey) {
            image = cached
            error = nil
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  let fetchedImage = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            AppAsyncImageCache.imageCache.setObject(fetchedImage, forKey: cacheKey)
            image = fetchedImage
            error = nil
        } catch {
            self.error = error
        }
    }
}
