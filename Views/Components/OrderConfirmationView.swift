import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            // Order Confirmation
            VStack(spacing: 8) {
                Text("Order Confirmed!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Thank you for your purchase")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Order Details
            VStack(spacing: 16) {
                DetailRow(title: "Order Number", value: order.id)
                DetailRow(title: "Date", value: order.date.formatted())
                DetailRow(title: "Total", value: String(format: "$%.2f", order.total))
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Shipping Address
            VStack(alignment: .leading, spacing: 8) {
                Text("Shipping Address")
                    .font(.headline)
                
                Text(order.shippingAddress.fullName)
                Text(order.shippingAddress.streetAddress)
                Text("\(order.shippingAddress.city), \(order.shippingAddress.state) \(order.shippingAddress.zipCode)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            
            // Continue Shopping Button
            Button(action: {
                dismiss()
            }) {
                Text("Continue Shopping")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct Order {
    let id: String
    let date: Date
    let total: Double
    let shippingAddress: Address
    let items: [CartItem]
}

#Preview {
    OrderConfirmationView(
        order: Order(
            id: "ORD123456",
            date: Date(),
            total: 99.99,
            shippingAddress: Address(
                fullName: "John Doe",
                streetAddress: "123 Main St",
                city: "New York",
                state: "NY",
                zipCode: "10001",
                phoneNumber: "123-456-7890"
            ),
            items: []
        )
    )
} 