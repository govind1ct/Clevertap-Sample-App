import SwiftUI

struct CartItemView: View {
    let item: CartItem
    @EnvironmentObject var cartManager: CartManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            Image(item.product.imageURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.headline)
                
                Text(item.product.formattedPrice)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                // Quantity Controls
                HStack {
                    Button(action: {
                        cartManager.updateQuantity(for: item.product, quantity: item.quantity - 1)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    
                    Text("\(item.quantity)")
                        .frame(width: 30)
                    
                    Button(action: {
                        cartManager.updateQuantity(for: item.product, quantity: item.quantity + 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            Spacer()
            
            // Remove Button
            Button(action: {
                cartManager.removeFromCart(item.product)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    CartItemView(item: CartItem(product: Product.samples[0], quantity: 1))
        .environmentObject(CartManager())
        .padding()
} 