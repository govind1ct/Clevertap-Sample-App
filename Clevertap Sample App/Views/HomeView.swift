import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var authViewModel: AuthViewModel

    @StateObject private var productService = ProductService()
    @StateObject private var productExperienceService = CleverTapProductExperiencesService.shared
    @StateObject private var profileService = ProfileService()

    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var showingCart = false

    private var categories: [String] {
        ["All"] + ProductCategory.allCases.map { $0.rawValue.capitalized }
    }

    private var filteredProducts: [Product] {
        let baseProducts = selectedCategory == "All"
            ? productService.products
            : productService.products.filter { $0.category.capitalized == selectedCategory }

        guard !searchText.isEmpty else { return baseProducts }

        return baseProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(searchText) ||
            product.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var featuredProducts: [Product] {
        Array(
            filteredProducts
                .filter { $0.isFeatured }
                .prefix(productExperienceService.maxFeaturedProducts)
        )
    }

    private var isInitialLoading: Bool {
        productService.isLoading && productService.products.isEmpty
    }

    private var currentDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }

    private var firstName: String {
        let profileName = profileService.userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = authViewModel.user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let source = !profileName.isEmpty ? profileName : displayName
        if !source.isEmpty {
            return source.components(separatedBy: " ").first ?? source
        }
        if let email = authViewModel.user?.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "There"
        }
        return "There"
    }

    var body: some View {
        ZStack {
            backgroundView

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    searchSection
                    categorySection

                    if isInitialLoading {
                        loadingSection
                    } else if let errorMessage = productService.errorMessage, productService.products.isEmpty {
                        errorSection(message: errorMessage)
                    } else if filteredProducts.isEmpty {
                        emptySection
                    } else {
                        if productExperienceService.showFeaturedSection, !featuredProducts.isEmpty {
                            featuredSection
                        }
                        productGridSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
            .refreshable {
                productService.fetchProducts()
                productExperienceService.fetchVariables()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCart) {
            CartView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            productService.fetchProducts()
            productExperienceService.fetchVariables()
            profileService.fetchUserProfile { _ in }
            CleverTapService.shared.trackScreenViewed(screenName: "Home")
        }
    }
}

private extension HomeView {
    var backgroundView: some View {
        LinearGradient(
            colors: [
                Color("CleverTapPrimary").opacity(0.18),
                Color("CleverTapSecondary").opacity(0.12),
                Color(.systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color("CleverTapPrimary").opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: -70, y: -80)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color("CleverTapSecondary").opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 36)
                .offset(x: 70, y: 80)
        }
        .ignoresSafeArea()
    }

    var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(currentDateLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text("Welcome, \(firstName)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(productExperienceService.homeHeaderSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    summaryPill(
                        icon: "shippingbox.fill",
                        text: "\(filteredProducts.count) products"
                    )
                    summaryPill(
                        icon: "square.grid.2x2.fill",
                        text: selectedCategory
                    )
                }
            }

            Spacer(minLength: 12)

            Button {
                showingCart = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")
                        .font(.title3)
                        .frame(width: 46, height: 46)
                        .liquidGlassSurface(shape: Circle())

                    if cartManager.itemCount > 0 {
                        Text("\(cartManager.itemCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.red, in: Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
            }
        }
        .padding(14)
        .liquidGlassSurface(cornerRadius: 22, tint: Color.white.opacity(0.06))
    }

    func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .liquidGlassSurface(shape: Capsule())
    }

    var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search products or categories", text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .liquidGlassSurface(cornerRadius: 16, tint: Color("CleverTapPrimary").opacity(0.08))
    }

    var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(categoryChipBackground(for: category), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    func categoryChipBackground(for category: String) -> AnyShapeStyle {
        if selectedCategory == category {
            AnyShapeStyle(
                LinearGradient(
                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            AnyShapeStyle(Color.white.opacity(0.35))
        }
    }

    var loadingSection: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.45))
                .frame(height: 280)
                .redacted(reason: .placeholder)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.45))
                        .frame(height: 190)
                        .redacted(reason: .placeholder)
                }
            }
        }
        .padding(.top, 8)
    }

    func errorSection(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                productService.fetchProducts()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .liquidGlassSurface(cornerRadius: 18, tint: Color.orange.opacity(0.08))
    }

    var emptySection: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 38))
                .foregroundColor(.secondary)
            Text("No matching products")
                .font(.headline)
            Text("Try another category or search keyword.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .liquidGlassSurface(cornerRadius: 18)
    }

    var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(productExperienceService.featuredSectionTitle)
                .font(.title2.weight(.bold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(featuredProducts) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            FeaturedProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var productGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("All Products")
                    .font(.title2.weight(.bold))
                Spacer()
                Text("\(filteredProducts.count) items")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 16
            ) {
                ForEach(filteredProducts) { product in
                    NavigationLink(destination: ProductDetailView(product: product)) {
                        GridProductCard(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct FeaturedProductCard: View {
    let product: Product

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AppAsyncImage(urlString: product.mainImageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.15)
                }
            }
            .frame(width: 290, height: 350)
            .clipShape(RoundedRectangle(cornerRadius: 26))

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26))

            VStack(alignment: .leading, spacing: 7) {
                Text("FEATURED")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white.opacity(0.85))

                Text(product.name)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(product.shortDescription ?? product.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("₹\(Int(product.price))")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    if product.originalPrice > product.price {
                        Text("₹\(Int(product.originalPrice))")
                            .font(.caption)
                            .strikethrough()
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(18)
        }
        .frame(width: 290, height: 350)
        .shadow(color: Color.black.opacity(0.2), radius: 14, y: 8)
    }
}

private struct GridProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AppAsyncImage(urlString: product.mainImageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.15)
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(product.category.capitalized)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.08), in: Capsule())

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(minHeight: 38, alignment: .top)

            HStack(spacing: 6) {
                Text("₹\(Int(product.price))")
                    .font(.headline.weight(.bold))
                if product.originalPrice > product.price {
                    Text("₹\(Int(product.originalPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
        }
        .padding(12)
        .liquidGlassSurface(cornerRadius: 18)
    }
}

private extension View {
    @ViewBuilder
    func liquidGlassSurface(cornerRadius: CGFloat = 18, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(true), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                self.glassEffect(.regular.interactive(true), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    func liquidGlassSurface<S: Shape>(shape: S, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint).interactive(true), in: shape)
            } else {
                self.glassEffect(.regular.interactive(true), in: shape)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.22), lineWidth: 1))
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(CartManager())
    }
}
