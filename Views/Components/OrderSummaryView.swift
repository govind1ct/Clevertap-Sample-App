import SwiftUI

struct OrderSummaryView: View {
    @EnvironmentObject var cartManager: CartManager
    let onCheckout: () -> Void
    
    var subtotal: Double {
        cartManager.items.reduce(0) { $0 + ($1.product.price * Double($1.quantity)) }
    }
    
    var shipping: Double {
        subtotal > 0 ? 5.99 : 0
    }
    
    var total: Double {
        subtotal + shipping
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Order Summary
            VStack(spacing: 12) {
                SummaryRow(title: "Subtotal", value: subtotal)
                SummaryRow(title: "Shipping", value: shipping)
                
                Divider()
                
                SummaryRow(
                    title: "Total",
                    value: total,
                    isTotal: true
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Checkout Button
            Button(action: onCheckout) {
                HStack {
                    Text("Proceed to Checkout")
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(cartManager.items.isEmpty)
            .opacity(cartManager.items.isEmpty ? 0.6 : 1)
        }
        .padding()
    }
}

struct SummaryRow: View {
    let title: String
    let value: Double
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline : .body)
            
            Spacer()
            
            Text(String(format: "$%.2f", value))
                .font(isTotal ? .headline : .body)
                .foregroundColor(isTotal ? .accentColor : .primary)
        }
    }
}

#Preview {
    OrderSummaryView(onCheckout: {})
        .environmentObject(CartManager())
} 