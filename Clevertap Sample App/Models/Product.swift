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
        case specifications
        case searchKeywords
        case createdAt
        case status
        case stockQuantity
        case lowStockThreshold
        case availabilityMessage
    }
    
    // Computed property to get the main image URL
    var mainImageURL: String {
        return imageURL ?? images.first ?? ""
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

    var isPurchasable: Bool {
        effectiveStatus == "active" && resolvedStockQuantity > 0
    }

    var isLowStock: Bool {
        isPurchasable && resolvedStockQuantity <= resolvedLowStockThreshold
    }

    var stockLabel: String {
        if effectiveStatus == "draft" { return "Draft" }
        if effectiveStatus == "archived" { return "Archived" }
        if resolvedStockQuantity == 0 { return "Out of Stock" }
        if isLowStock { return "Low Stock" }
        return "In Stock"
    }
    
    // CleverTap Event Properties
    var properties: [String: Any] {
        return [
            "product_id": id,
            "product_name": name,
            "price": price,
            "category": category,
            "status": effectiveStatus,
            "stock_quantity": resolvedStockQuantity
        ]
    }
}
