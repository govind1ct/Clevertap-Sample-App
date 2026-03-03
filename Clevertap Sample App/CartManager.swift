import Foundation
import SwiftUI

struct CartItem: Identifiable, Codable {
    let id: String
    let product: Product
    var quantity: Int
}

class CartManager: ObservableObject {
    @Published var items: [CartItem] = []

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
} 