import SwiftUI

struct HomeView: View {
    @State private var selectedCategory: ProductCategory?
    @State private var searchText = ""
    @State private var showingProfile = false
    @State private var showingCart = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Featured Products
                    FeaturedProductsSection()
                    
                    // Categories
                    CategorySection(selectedCategory: $selectedCategory)
                    
                    // Crystal Guide
                    CrystalGuideSection()
                    
                    // Special Offers
                    SpecialOffersSection()
                }
                .padding()
            }
            .navigationTitle("Crystal Shop")
            .searchable(text: $searchText, prompt: "Search products...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCart.toggle()
                    } label: {
                        Image(systemName: "cart.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingProfile.toggle()
                    } label: {
                        Image(systemName: "person.fill")
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingCart) {
                CartView()
            }
        }
    }
}

// Featured Products Section
struct FeaturedProductsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Products")
                .font(.title2)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<5) { _ in
                        ProductCard(product: Product.sample)
                            .frame(width: 160)
                    }
                }
            }
        }
    }
}

// Category Section
struct CategorySection: View {
    @Binding var selectedCategory: ProductCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title2)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ProductCategory.allCases, id: \.self) { category in
                        CategoryFilterButton(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
}

// Crystal Guide Section
struct CrystalGuideSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crystal Guide")
                .font(.title2)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        CrystalGuideCard()
                            .frame(width: 280)
                    }
                }
            }
        }
    }
}

// Special Offers Section
struct SpecialOffersSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Offers")
                .font(.title2)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        SpecialOfferCard()
                            .frame(width: 280)
                    }
                }
            }
        }
    }
}

// Crystal Guide Card
struct CrystalGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("crystal-guide")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .clipped()
                .cornerRadius(12)
            
            Text("Crystal Properties")
                .font(.headline)
            
            Text("Learn about crystal meanings and healing properties")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Special Offer Card
struct SpecialOfferCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("special-offer")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .clipped()
                .cornerRadius(12)
            
            Text("Summer Sale")
                .font(.headline)
            
            Text("Up to 50% off on selected items")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    HomeView()
} 