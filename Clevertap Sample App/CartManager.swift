import Foundation
import SwiftUI
import FirebaseAuth

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

    private let storageKeyPrefix = "persisted_cart_items"
    private let guestStorageKeySuffix = "guest"
    private var activeUserID: String?
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    private var isHydrating = false

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
            self.merchandisingPriority = product.merchandisingPriority
            self.isCategoryPinned = product.isCategoryPinned
            self.categorySortPriority = product.categorySortPriority
            self.homePlacementSlot = product.homePlacementSlot
            self.campaignTags = product.campaignTags
            self.featuredStartAt = product.featuredStartAt
            self.featuredEndAt = product.featuredEndAt
            self.newLaunchStartAt = product.newLaunchStartAt
            self.newLaunchEndAt = product.newLaunchEndAt
            self.specifications = product.specifications
            self.searchKeywords = product.searchKeywords
            self.createdAt = product.createdAt
            self.status = product.status
            self.stockQuantity = product.stockQuantity
            self.lowStockThreshold = product.lowStockThreshold
            self.availabilityMessage = product.availabilityMessage
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
                merchandisingPriority: merchandisingPriority,
                isCategoryPinned: isCategoryPinned,
                categorySortPriority: categorySortPriority,
                homePlacementSlot: homePlacementSlot,
                campaignTags: campaignTags,
                featuredStartAt: featuredStartAt,
                featuredEndAt: featuredEndAt,
                newLaunchStartAt: newLaunchStartAt,
                newLaunchEndAt: newLaunchEndAt,
                specifications: specifications,
                searchKeywords: searchKeywords,
                createdAt: createdAt,
                status: status,
                stockQuantity: stockQuantity,
                lowStockThreshold: lowStockThreshold,
                availabilityMessage: availabilityMessage
            )
        }
    }

    private struct PersistedCartItem: Codable {
        let id: String
        let product: PersistedProduct
        let quantity: Int
    }

    init() {
        activeUserID = Auth.auth().currentUser?.uid
        loadCartItems(for: activeUserID)
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.handleAuthStateChange(userID: user?.uid)
        }
    }

    deinit {
        if let authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(authStateListenerHandle)
        }
    }

    func addToCart(_ product: Product) {
        addToCart(product, quantity: 1)
    }

    func addToCart(_ product: Product, quantity: Int) {
        guard product.isPurchasable else { return }
        let quantityToAdd = max(1, min(quantity, product.resolvedStockQuantity))
        guard quantityToAdd > 0 else { return }

        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity = min(items[index].quantity + quantityToAdd, product.resolvedStockQuantity)
        } else {
            items.append(CartItem(id: product.id ?? UUID().uuidString, product: product, quantity: quantityToAdd))
        }

        CleverTapService.shared.trackProductAddedToCart(
            productId: product.id ?? product.name,
            productName: product.name,
            category: product.category,
            price: product.price,
            quantity: quantityToAdd
        )
    }

    func removeFromCart(_ product: Product) {
        items.removeAll { $0.product.id == product.id }
    }

    func updateQuantity(for product: Product, quantity: Int) {
        guard let index = items.firstIndex(where: { $0.product.id == product.id }) else { return }

        let maxAllowedQuantity = max(product.resolvedStockQuantity, 1)
        items[index].quantity = min(max(1, quantity), maxAllowedQuantity)
        items[index] = CartItem(id: items[index].id, product: product, quantity: items[index].quantity)
    }

    func replaceItems(_ newItems: [CartItem]) {
        items = newItems
    }

    var total: Double {
        items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    private func storageKey(for userID: String?) -> String {
        let normalizedUserID = userID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = normalizedUserID.flatMap { $0.isEmpty ? nil : $0 } ?? guestStorageKeySuffix
        return "\(storageKeyPrefix).\(suffix)"
    }

    private func handleAuthStateChange(userID: String?) {
        guard activeUserID != userID else { return }
        activeUserID = userID
        loadCartItems(for: userID)
    }

    private func saveCartItems() {
        guard !isHydrating else { return }

        do {
            let persistedItems = items.map {
                PersistedCartItem(id: $0.id, product: PersistedProduct(from: $0.product), quantity: $0.quantity)
            }
            let encodedData = try JSONEncoder().encode(persistedItems)
            UserDefaults.standard.set(encodedData, forKey: storageKey(for: activeUserID))
        } catch {
            print("Failed to save cart items: \(error)")
        }
    }

    private func loadCartItems(for userID: String?) {
        isHydrating = true
        defer { isHydrating = false }

        guard let savedData = UserDefaults.standard.data(forKey: storageKey(for: userID)) else {
            items = []
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
