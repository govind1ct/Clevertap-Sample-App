import Foundation
import FirebaseFirestore

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let shortDescription: String?
    let price: Double
    let originalPrice: Double
    let purposes: [String]
    let category: String
    let chakras: [String]
    let energyLevel: Int
    let images: [String]
    let imageURL: String?
    let benefits: [String]
    let careInstructions: String
    let isNewLaunch: Bool
    let isFeatured: Bool
    let merchandisingPriority: Int?
    let isCategoryPinned: Bool?
    let categorySortPriority: Int?
    let homePlacementSlot: Int?
    let campaignTags: [String]?
    let featuredStartAt: Date?
    let featuredEndAt: Date?
    let newLaunchStartAt: Date?
    let newLaunchEndAt: Date?
    let specifications: [String: String]?
    let searchKeywords: [String]
    let createdAt: Date?
    let status: String?
    let stockQuantity: Int?
    let lowStockThreshold: Int?
    let availabilityMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case shortDescription
        case price
        case originalPrice
        case purposes
        case category
        case chakras
        case energyLevel
        case images
        case imageURL
        case benefits
        case careInstructions
        case isNewLaunch
        case isFeatured
        case merchandisingPriority
        case isCategoryPinned
        case categorySortPriority
        case homePlacementSlot
        case campaignTags
        case featuredStartAt
        case featuredEndAt
        case newLaunchStartAt
        case newLaunchEndAt
        case specifications
        case searchKeywords
        case createdAt
        case status
        case stockQuantity
        case lowStockThreshold
        case availabilityMessage
    }
    
    var mainImageURL: String {
        imageURL ?? images.first ?? ""
    }

    var effectiveStatus: String {
        let normalized = status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return normalized.isEmpty ? "active" : normalized
    }

    var resolvedStockQuantity: Int {
        max(stockQuantity ?? 0, 0)
    }

    var resolvedLowStockThreshold: Int {
        max(lowStockThreshold ?? 3, 1)
    }

    var resolvedMerchandisingPriority: Int {
        merchandisingPriority ?? 0
    }

    var resolvedCategoryPinned: Bool {
        isCategoryPinned ?? false
    }

    var resolvedCategorySortPriority: Int {
        categorySortPriority ?? 0
    }

    var resolvedHomePlacementSlot: Int? {
        guard let homePlacementSlot, homePlacementSlot > 0 else { return nil }
        return homePlacementSlot
    }

    var resolvedCampaignTags: [String] {
        campaignTags ?? []
    }

    var isPurchasable: Bool {
        effectiveStatus == "active" && resolvedStockQuantity > 0
    }

    var isLowStock: Bool {
        isPurchasable && resolvedStockQuantity <= resolvedLowStockThreshold
    }

    var isFeaturedActive: Bool {
        isFeatured && isWithinSchedule(start: featuredStartAt, end: featuredEndAt)
    }

    var isNewLaunchActive: Bool {
        isNewLaunch && isWithinSchedule(start: newLaunchStartAt, end: newLaunchEndAt)
    }

    var stockLabel: String {
        if effectiveStatus == "draft" { return "Draft" }
        if effectiveStatus == "archived" { return "Archived" }
        if resolvedStockQuantity == 0 { return "Out of Stock" }
        if isLowStock { return "Low Stock" }
        return "In Stock"
    }

    var properties: [String: Any] {
        [
            "product_id": id ?? NSNull(),
            "product_name": name,
            "price": price,
            "category": category,
            "status": effectiveStatus,
            "stock_quantity": resolvedStockQuantity,
            "merchandising_priority": resolvedMerchandisingPriority,
            "is_category_pinned": resolvedCategoryPinned,
            "category_sort_priority": resolvedCategorySortPriority,
            "home_placement_slot": resolvedHomePlacementSlot ?? NSNull(),
            "campaign_tags": resolvedCampaignTags
        ]
    }

    private func isWithinSchedule(start: Date?, end: Date?) -> Bool {
        let now = Date()
        if let start, now < start { return false }
        if let end, now > end { return false }
        return true
    }
}
