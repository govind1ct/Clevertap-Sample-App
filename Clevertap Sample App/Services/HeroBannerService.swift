import Foundation
import FirebaseFirestore

final class HeroBannerService: ObservableObject {
    @Published var banners: [HeroBanner] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let includeInactiveBanners: Bool

    init(includeInactiveBanners: Bool = false) {
        self.includeInactiveBanners = includeInactiveBanners
    }

    func fetchBanners() {
        isLoading = true
        errorMessage = nil

        db.collection("hero_banners").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.errorMessage = error.localizedDescription
                    self.banners = []
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No hero banner data was returned."
                    self.banners = []
                    return
                }

                var decodedBanners = documents.compactMap { document in
                    try? document.data(as: HeroBanner.self)
                }

                if !self.includeInactiveBanners {
                    decodedBanners = decodedBanners.filter { $0.isScheduledActive }
                }

                self.banners = decodedBanners.sorted(by: Self.bannerSortOrder)
            }
        }
    }

    var activeBanners: [HeroBanner] {
        banners
            .filter { includeInactiveBanners ? true : $0.isScheduledActive }
            .sorted(by: Self.bannerSortOrder)
    }

    private static func bannerSortOrder(_ lhs: HeroBanner, _ rhs: HeroBanner) -> Bool {
        if lhs.resolvedPriority != rhs.resolvedPriority {
            return lhs.resolvedPriority < rhs.resolvedPriority
        }
        return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
    }
}
