import Foundation
import SwiftUI

struct CartItem: Identifiable, Codable {
    let id: String
    let product: Product
    var quantity: Int
}

class CartManager: ObservableObject {
    @Published var items: [CartItem] = [] {
        didSet {
            saveCartItems()
        }
    }

    private let storageKey = "persisted_cart_items"

    // Use plain Codable storage models instead of Product directly.
    // Product includes Firestore-specific property wrappers, which can fail with JSONDecoder.
    private struct PersistedProduct: Codable {
        let id: String?
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

        init(from product: Product) {
            self.id = product.id
            self.name = product.name
            self.description = product.description
            self.shortDescription = product.shortDescription
            self.price = product.price
            self.originalPrice = product.originalPrice
            self.purposes = product.purposes
            self.category = product.category
            self.chakras = product.chakras
            self.energyLevel = product.energyLevel
            self.images = product.images
            self.imageURL = product.imageURL
            self.benefits = product.benefits
            self.careInstructions = product.careInstructions
            self.isNewLaunch = product.isNewLaunch
            self.isFeatured = product.isFeatured
            self.specifications = product.specifications
            self.searchKeywords = product.searchKeywords
            self.createdAt = product.createdAt
        }

        var product: Product {
            Product(
                id: id,
                name: name,
                description: description,
                shortDescription: shortDescription,
                price: price,
                originalPrice: originalPrice,
                purposes: purposes,
                category: category,
                chakras: chakras,
                energyLevel: energyLevel,
                images: images,
                imageURL: imageURL,
                benefits: benefits,
                careInstructions: careInstructions,
                isNewLaunch: isNewLaunch,
                isFeatured: isFeatured,
                specifications: specifications,
                searchKeywords: searchKeywords,
                createdAt: createdAt
            )
        }
    }

    private struct PersistedCartItem: Codable {
        let id: String
        let product: PersistedProduct
        let quantity: Int
    }

    init() {
        loadCartItems()
    }

    func addToCart(_ product: Product) {
        addToCart(product, quantity: 1)
    }

    func addToCart(_ product: Product, quantity: Int) {
        let quantityToAdd = max(1, quantity)

        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantityToAdd
        } else {
            items.append(CartItem(id: product.id ?? UUID().uuidString, product: product, quantity: quantityToAdd))
        }
    }

    func removeFromCart(_ product: Product) {
        items.removeAll { $0.product.id == product.id }
    }

    func updateQuantity(for product: Product, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity = max(1, quantity)
        }
    }

    var total: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    private func saveCartItems() {
        do {
            let persistedItems = items.map {
                PersistedCartItem(id: $0.id, product: PersistedProduct(from: $0.product), quantity: $0.quantity)
            }
            let encodedData = try JSONEncoder().encode(persistedItems)
            UserDefaults.standard.set(encodedData, forKey: storageKey)
        } catch {
            print("Failed to save cart items: \(error)")
        }
    }

    private func loadCartItems() {
        guard let savedData = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            let decoded = try JSONDecoder().decode([PersistedCartItem].self, from: savedData)
            items = decoded.map {
                CartItem(id: $0.id, product: $0.product.product, quantity: max(1, $0.quantity))
            }
        } catch {
            print("Failed to load cart items: \(error)")
            items = []
        }
    }
}
