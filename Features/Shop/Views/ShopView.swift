import SwiftUI

struct ShopView: View {
    @StateObject private var shopService = ShopService()
    @EnvironmentObject var cartManager: CartManager
    @State private var selectedCategory: ProductCategory? = nil
    @State private var searchText: String = ""
    
    var filteredProducts: [Product] {
        var products = shopService.products
        if let category = selectedCategory {
            products = products.filter { $0.category.lowercased() == category.rawValue.lowercased() }
        }
        if !searchText.isEmpty {
            products = shopService.searchProducts(keyword: searchText)
        }
        return products
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ProductCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = (selectedCategory == category) ? nil : category
                            }) {
                                Text(category.rawValue.capitalized)
                                    .fontWeight(selectedCategory == category ? .bold : .regular)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedCategory == category ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Search Bar
                HStack {
                    TextField("Search products...", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.vertical, 4)
                
                // Product Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product)
                                .environmentObject(cartManager)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Shop")
            .onAppear {
                shopService.fetchProducts()
            }
        }
    }
} 