import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedImageIndex = 0
    @State private var quantity = 1
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Image Gallery
                TabView(selection: $selectedImageIndex) {
                    ForEach(0..<product.images.count, id: \.self) { index in
                        Image(product.images[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .tag(index)
                    }
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle())
                
                VStack(alignment: .leading, spacing: 16) {
                    // Product Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(product.formattedPrice)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        
                        HStack {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(product.rating) ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            
                            Text("(\(product.reviewCount) reviews)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(product.description)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Quantity Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quantity")
                            .font(.headline)
                        
                        HStack {
                            Button(action: {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                            
                            Text("\(quantity)")
                                .frame(width: 40)
                            
                            Button(action: {
                                quantity += 1
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Add to Cart Button
                    Button(action: {
                        cartManager.addToCart(product: product, quantity: quantity)
                    }) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("Add to Cart")
                        }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add to wishlist
                }) {
                    Image(systemName: "heart")
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ProductDetailView(product: Product.samples[0])
            .environmentObject(CartManager())
    }
} 