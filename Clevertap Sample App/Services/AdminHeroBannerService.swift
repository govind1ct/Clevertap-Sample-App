import Foundation
import FirebaseFirestore

final class AdminHeroBannerService: ObservableObject {
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func createBanner(from data: AdminHeroBannerFormData, completion: @escaping (Result<String, Error>) -> Void) {
        isSaving = true
        errorMessage = nil

        let documentRef = db.collection("hero_banners").document()
        let payload = data.toFirestoreData(includeCreatedAt: true)

        documentRef.setData(payload, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "create",
                        entityType: "hero_banner",
                        entityId: documentRef.documentID,
                        metadata: ["title": data.title]
                    )
                    completion(.success(documentRef.documentID))
                }
            }
        }
    }

    func updateBanner(bannerID: String, data: AdminHeroBannerFormData, completion: @escaping (Result<Void, Error>) -> Void) {
        isSaving = true
        errorMessage = nil

        let payload = data.toFirestoreData(includeCreatedAt: false)
        db.collection("hero_banners").document(bannerID).setData(payload, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "update",
                        entityType: "hero_banner",
                        entityId: bannerID,
                        metadata: ["title": data.title]
                    )
                    completion(.success(()))
                }
            }
        }
    }

    func deleteBanner(bannerID: String, title: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        isSaving = true
        errorMessage = nil

        db.collection("hero_banners").document(bannerID).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "delete",
                        entityType: "hero_banner",
                        entityId: bannerID,
                        metadata: ["title": title ?? ""]
                    )
                    completion(.success(()))
                }
            }
        }
    }

    func updateBannerPriority(
        bannerID: String,
        title: String?,
        priority: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isSaving = true
        errorMessage = nil

        db.collection("hero_banners").document(bannerID).setData(["priority": max(priority, 0)], merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.isSaving = false
                if let error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    AdminAuditLogger.log(
                        action: "reorder",
                        entityType: "hero_banner",
                        entityId: bannerID,
                        metadata: [
                            "title": title ?? "",
                            "priority": max(priority, 0)
                        ]
                    )
                    completion(.success(()))
                }
            }
        }
    }
}

struct AdminHeroBannerFormData {
    var title: String = ""
    var subtitle: String = ""
    var imageURL: String = ""
    var mobileImageURL: String = ""
    var backgroundHex: String = ""
    var accentHex: String = ""
    var ctaText: String = ""
    var ctaDeepLink: String = ""
    var linkedProductID: String = ""
    var campaignTag: String = ""
    var offerLabel: String = ""
    var offerCode: String = ""
    var isActive: Bool = true
    var priority: Int = 0
    var hasSchedule: Bool = false
    var startAt: Date = Date()
    var endAt: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()

    init() {}

    init(from banner: HeroBanner) {
        title = banner.title
        subtitle = banner.subtitle
        imageURL = banner.imageURL
        mobileImageURL = banner.mobileImageURL ?? ""
        backgroundHex = banner.backgroundHex ?? ""
        accentHex = banner.accentHex ?? ""
        ctaText = banner.ctaText ?? ""
        ctaDeepLink = banner.ctaDeepLink ?? ""
        linkedProductID = banner.linkedProductID ?? ""
        campaignTag = banner.campaignTag ?? ""
        offerLabel = banner.offerLabel ?? ""
        offerCode = banner.offerCode ?? ""
        isActive = banner.isActive
        priority = banner.priority
        hasSchedule = banner.startAt != nil || banner.endAt != nil
        startAt = banner.startAt ?? Date()
        endAt = banner.endAt ?? (Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date())
    }

    func toFirestoreData(includeCreatedAt: Bool) -> [String: Any] {
        var data: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "subtitle": subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            "imageURL": imageURL.trimmingCharacters(in: .whitespacesAndNewlines),
            "isActive": isActive,
            "priority": max(priority, 0)
        ]

        let mobileImageValue = mobileImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !mobileImageValue.isEmpty {
            data["mobileImageURL"] = mobileImageValue
        } else {
            data["mobileImageURL"] = FieldValue.delete()
        }

        let backgroundHexValue = backgroundHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if !backgroundHexValue.isEmpty {
            data["backgroundHex"] = backgroundHexValue
        } else {
            data["backgroundHex"] = FieldValue.delete()
        }

        let accentHexValue = accentHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if !accentHexValue.isEmpty {
            data["accentHex"] = accentHexValue
        } else {
            data["accentHex"] = FieldValue.delete()
        }

        let ctaTextValue = ctaText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ctaTextValue.isEmpty {
            data["ctaText"] = ctaTextValue
        } else {
            data["ctaText"] = FieldValue.delete()
        }

        let ctaDeepLinkValue = ctaDeepLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ctaDeepLinkValue.isEmpty {
            data["ctaDeepLink"] = ctaDeepLinkValue
        } else {
            data["ctaDeepLink"] = FieldValue.delete()
        }

        let linkedProductIDValue = linkedProductID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !linkedProductIDValue.isEmpty {
            data["linkedProductID"] = linkedProductIDValue
        } else {
            data["linkedProductID"] = FieldValue.delete()
        }

        let campaignTagValue = campaignTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !campaignTagValue.isEmpty {
            data["campaignTag"] = campaignTagValue
        } else {
            data["campaignTag"] = FieldValue.delete()
        }

        let offerLabelValue = offerLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !offerLabelValue.isEmpty {
            data["offerLabel"] = offerLabelValue
        } else {
            data["offerLabel"] = FieldValue.delete()
        }

        let offerCodeValue = offerCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if !offerCodeValue.isEmpty {
            data["offerCode"] = offerCodeValue
        } else {
            data["offerCode"] = FieldValue.delete()
        }

        if hasSchedule {
            data["startAt"] = startAt
            data["endAt"] = endAt
        } else {
            data["startAt"] = FieldValue.delete()
            data["endAt"] = FieldValue.delete()
        }

        if includeCreatedAt {
            data["createdAt"] = Date()
        }

        return data
    }
}
