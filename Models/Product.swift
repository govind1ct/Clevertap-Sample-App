import Foundation

struct Product: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let imageURL: String
    let category: String
    let rating: Double
    let reviewCount: Int
    var isFavorite: Bool = false
    
    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

// Sample data
extension Product {
    static let samples = [
        Product(
            id: "1",
            name: "Amethyst Crystal",
            description: "Beautiful purple amethyst crystal known for its calming properties.",
            price: 29.99,
            imageURL: "amethyst",
            category: "Crystals",
            rating: 4.8,
            reviewCount: 124
        ),
        Product(
            id: "2",
            name: "Rose Quartz Pendant",
            description: "Elegant rose quartz pendant necklace for love and harmony.",
            price: 39.99,
            imageURL: "rose_quartz",
            category: "Jewelry",
            rating: 4.9,
            reviewCount: 89
        ),
        Product(
            id: "3",
            name: "Crystal Healing Guide",
            description: "Comprehensive guide to crystal healing and properties.",
            price: 19.99,
            imageURL: "crystal_book",
            category: "Books",
            rating: 4.7,
            reviewCount: 56
        )
    ]
} 