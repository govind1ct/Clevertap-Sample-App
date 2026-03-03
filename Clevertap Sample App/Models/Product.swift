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
    }
    
    // Computed property to get the main image URL
    var mainImageURL: String {
        return imageURL ?? images.first ?? ""
    }
    
    // CleverTap Event Properties
    var properties: [String: Any] {
        return [
            "product_id": id,
            "product_name": name,
            "price": price,
            "category": category
        ]
    }
} 
