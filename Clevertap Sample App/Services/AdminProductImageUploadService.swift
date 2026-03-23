import Foundation
import FirebaseStorage
import UIKit

final class AdminProductImageUploadService: ObservableObject {
    @Published var isUploading = false

    private let storage = Storage.storage()

    func uploadProductImage(_ image: UIImage, kind: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            throw AdminProductImageUploadError.processingFailed
        }

        await MainActor.run {
            isUploading = true
        }

        defer {
            Task { @MainActor in
                isUploading = false
            }
        }

        let sanitizedKind = kind.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "gallery" : kind
        let imageRef = storage.reference().child("product_images/\(sanitizedKind)/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            imageRef.putData(imageData, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            imageRef.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AdminProductImageUploadError.downloadURLMissing)
                }
            }
        }

        return downloadURL.absoluteString
    }
}

enum AdminProductImageUploadError: LocalizedError {
    case processingFailed
    case downloadURLMissing

    var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Failed to process the selected image."
        case .downloadURLMissing:
            return "Image uploaded, but the download URL could not be retrieved."
        }
    }
}
