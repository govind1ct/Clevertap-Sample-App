import Foundation
import SwiftUI

class CartManager: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var total: Double = 0.0
    
    func addToCart(product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
        calculateTotal()
    }
    
    func removeFromCart(product: Product) {
        items.removeAll { $0.product.id == product.id }
        calculateTotal()
    }
    
    func updateQuantity(for product: Product, quantity: Int) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            if quantity > 0 {
                items[index].quantity = quantity
            } else {
                items.remove(at: index)
            }
        }
        calculateTotal()
    }
    
    private func calculateTotal() {
        total = items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    func clearCart() {
        items.removeAll()
        total = 0
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: Product
    var quantity: Int
} 