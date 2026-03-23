import Foundation
import FirebaseFirestore

struct HeroBanner: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let subtitle: String
    let imageURL: String
    let mobileImageURL: String?
    let backgroundHex: String?
    let accentHex: String?
    let ctaText: String?
    let ctaDeepLink: String?
    let linkedProductID: String?
    let campaignTag: String?
    let offerLabel: String?
    let offerCode: String?
    let isActive: Bool
    let priority: Int
    let startAt: Date?
    let endAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case imageURL
        case mobileImageURL
        case backgroundHex
        case accentHex
        case ctaText
        case ctaDeepLink
        case linkedProductID
        case campaignTag
        case offerLabel
        case offerCode
        case isActive
        case priority
        case startAt
        case endAt
        case createdAt
    }

    var resolvedMobileImageURL: String {
        let mobileValue = mobileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return mobileValue.isEmpty ? imageURL : mobileValue
    }

    var resolvedPriority: Int {
        max(priority, 0)
    }

    var isScheduledActive: Bool {
        guard isActive else { return false }
        let now = Date()
        if let startAt, now < startAt { return false }
        if let endAt, now > endAt { return false }
        return true
    }

    var hasOffer: Bool {
        let label = offerLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let code = offerCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !label.isEmpty || !code.isEmpty
    }
}
