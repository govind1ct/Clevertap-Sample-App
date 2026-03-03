import SwiftUI

struct HomeView: View {
    @StateObject private var productService = ProductService()
    @EnvironmentObject var cartManager: CartManager
    
    var featuredProducts: [Product] {
        productService.products.filter { $0.isFeatured || $0.isNewLaunch }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Carousel
                    if !featuredProducts.isEmpty {
                        TabView {
                            ForEach(featuredProducts) { product in
                                FeaturedProductCard(product: product)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .frame(height: 320)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                        .padding(.top, 8)
                    }
                    
                    // Product Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shop Products")
                            .font(.title2.bold())
                            .padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(productService.products) { product in
                                ProductCard(product: product)
                                    .environmentObject(cartManager)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Cavacham")
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.08), Color.yellow.opacity(0.04), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
            )
            .onAppear {
                productService.fetchProducts()
            }
        }
    }
}

struct FeaturedProductCard: View {
    let product: Product
    var body: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: product.images.first ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(24)
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.2), Color.clear],
                    startPoint: .top, endPoint: .bottom
                ).cornerRadius(24)
            )
            VStack(alignment: .leading, spacing: 8) {
                if product.isNewLaunch {
                    BadgeView(text: "NEW", color: .blue)
                } else if product.isFeatured {
                    BadgeView(text: "FEATURED", color: .purple)
                }
                Spacer()
                Text(product.name)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                Text(product.shortDescription ?? product.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            .padding(20)
        }
        .frame(height: 220)
        .shadow(radius: 12, y: 8)
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.85))
            .foregroundColor(.white)
            .cornerRadius(10)
    }
} 