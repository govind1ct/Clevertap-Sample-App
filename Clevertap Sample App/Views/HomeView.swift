import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var authViewModel: AuthViewModel

    @StateObject private var productService = ProductService()
    @StateObject private var productExperienceService = CleverTapProductExperiencesService.shared
    @StateObject private var profileService = ProfileService()
    @EnvironmentObject private var themeManager: ThemeManager
    @Namespace private var productTransitionNamespace

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
                VStack(spacing: themeManager.sectionSpacing) {
                    headerSection
                    searchSection
                    categorySection
                    HomeNativeDisplayView()

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
            colors: themeManager.backgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(themeManager.primaryButtonBackground.opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: -70, y: -80)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(themeManager.secondaryButtonBackground.opacity(0.18))
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
                    .foregroundColor(themeManager.bodyTextColor)
                    .textCase(.uppercase)

                if productExperienceService.showHomeHeaderBadge,
                   !productExperienceService.homeHeaderBadge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(productExperienceService.homeHeaderBadge.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundColor(themeManager.titleTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(themeManager.cardBackground.opacity(0.8), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(themeManager.cardBorder, lineWidth: 1)
                        )
                }

                Text(productExperienceService.homeHeaderTitle)
                    .font(.custom(themeManager.titleFontName, size: 32))
                    .foregroundColor(themeManager.titleTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Welcome, \(firstName)")
                    .font(.custom(themeManager.bodyFontName, size: 12))
                    .foregroundColor(themeManager.bodyTextColor)

                Text(productExperienceService.homeHeaderSubtitle)
                    .font(.custom(themeManager.bodyFontName, size: 14))
                    .foregroundColor(themeManager.bodyTextColor)
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
                        .background(themeManager.cardBackground.opacity(0.85), in: Circle())
                        .overlay(
                            Circle()
                                .stroke(themeManager.cardBorder, lineWidth: 1)
                        )

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
        .background(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius, style: .continuous)
                .fill(themeManager.cardBackground.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius, style: .continuous)
                .stroke(themeManager.cardBorder, lineWidth: 1)
        )
        .shadow(color: themeManager.cardBorder.opacity(themeManager.cardShadowOpacity), radius: 12, y: 8)
    }

    func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundColor(themeManager.bodyTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeManager.cardBackground.opacity(0.75), in: Capsule())
        .overlay(
            Capsule()
                .stroke(themeManager.cardBorder, lineWidth: 1)
        )
    }

    var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.bodyTextColor)

            TextField("Search products or categories", text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.bodyTextColor)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius, style: .continuous)
                .fill(themeManager.cardBackground.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius, style: .continuous)
                .stroke(themeManager.cardBorder, lineWidth: 1)
        )
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
                            .foregroundColor(selectedCategory == category ? themeManager.primaryButtonText : themeManager.bodyTextColor)
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
                    colors: [themeManager.primaryButtonBackground, themeManager.secondaryButtonBackground],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            AnyShapeStyle(themeManager.cardBackground.opacity(0.6))
        }
    }

    private var homeBackgroundGradientColors: [Color] {
        if let start = colorFromHex(productExperienceService.homeThemeGradientStart),
           let end = colorFromHex(productExperienceService.homeThemeGradientEnd) {
            return [start, end, Color(.systemGroupedBackground)]
        }
        return [
            Color("CleverTapPrimary").opacity(0.18),
            Color("CleverTapSecondary").opacity(0.12),
            Color(.systemGroupedBackground)
        ]
    }

    private func colorFromHex(_ hex: String) -> Color? {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard normalized.count == 6, let value = Int(normalized, radix: 16) else { return nil }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
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
                .font(.custom(themeManager.titleFontName, size: 22))
                .foregroundColor(themeManager.titleTextColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(featuredProducts) { product in
                        NavigationLink {
                            if #available(iOS 17.0, *) {
                                ProductDetailView(product: product)
                                    .navigationTransition(.zoom(sourceID: "featured-\(product.id ?? product.name)", in: productTransitionNamespace))
                            } else {
                                ProductDetailView(product: product)
                            }
                        } label: {
                            FeaturedProductCard(product: product)
                                .matchedTransitionIfAvailable(id: "featured-\(product.id ?? product.name)", in: productTransitionNamespace)
                        }
                        .buttonStyle(ProductPressStyle())
                        .transaction { transaction in
                            transaction.animation = .spring(response: 0.48, dampingFraction: 0.9)
                        }
                    }
                }
            }
        }
    }

    var productGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("All Products")
                    .font(.custom(themeManager.titleFontName, size: 22))
                    .foregroundColor(themeManager.titleTextColor)
                Spacer()
                Text("\(filteredProducts.count) items")
                    .font(.custom(themeManager.bodyFontName, size: 12))
                    .foregroundColor(themeManager.bodyTextColor)
            }

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 16
            ) {
                ForEach(filteredProducts) { product in
                    NavigationLink {
                        if #available(iOS 17.0, *) {
                            ProductDetailView(product: product)
                                .navigationTransition(.zoom(sourceID: "grid-\(product.id ?? product.name)", in: productTransitionNamespace))
                        } else {
                            ProductDetailView(product: product)
                        }
                    } label: {
                        GridProductCard(product: product)
                            .matchedTransitionIfAvailable(id: "grid-\(product.id ?? product.name)", in: productTransitionNamespace)
                    }
                    .buttonStyle(ProductPressStyle())
                    .transaction { transaction in
                        transaction.animation = .spring(response: 0.48, dampingFraction: 0.9)
                    }
                }
            }
        }
    }

}

private extension View {
    @ViewBuilder
    func matchedTransitionIfAvailable(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 17.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}

private struct ProductPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .rotation3DEffect(.degrees(configuration.isPressed ? 4 : 0), axis: (x: 1, y: -1, z: 0))
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.18 : 0.08), radius: configuration.isPressed ? 16 : 8, y: configuration.isPressed ? 10 : 6)
            .animation(.spring(response: 0.34, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

private struct FeaturedProductCard: View {
    let product: Product
    @EnvironmentObject private var themeManager: ThemeManager

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
                colors: [.clear, Color.black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26))

            VStack(alignment: .leading, spacing: 7) {
                Text("FEATURED")
                    .font(.custom(themeManager.bodyFontName, size: 11))
                    .foregroundColor(themeManager.titleTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.cardBackground.opacity(0.85), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(themeManager.cardBorder, lineWidth: 1)
                    )

                Text(product.name)
                    .font(.custom(themeManager.titleFontName, size: 20))
                    .foregroundColor(themeManager.titleTextColor)
                    .lineLimit(2)

                Text(product.shortDescription ?? product.category.capitalized)
                    .font(.custom(themeManager.bodyFontName, size: 12))
                    .foregroundColor(themeManager.bodyTextColor)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("₹\(Int(product.price))")
                        .font(.custom(themeManager.titleFontName, size: 16))
                        .foregroundColor(themeManager.titleTextColor)
                    if product.originalPrice > product.price {
                        Text("₹\(Int(product.originalPrice))")
                            .font(.custom(themeManager.bodyFontName, size: 11))
                            .strikethrough()
                            .foregroundColor(themeManager.bodyTextColor)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeManager.cardBackground.opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(themeManager.cardBorder, lineWidth: 1)
            )
            .padding(16)
        }
        .frame(width: 290, height: 350)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(themeManager.cardBorder, lineWidth: 1)
        )
        .shadow(color: themeManager.cardBorder.opacity(themeManager.cardShadowOpacity), radius: 14, y: 8)
    }
}

private struct GridProductCard: View {
    let product: Product
    @EnvironmentObject private var themeManager: ThemeManager

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
                .font(.custom(themeManager.bodyFontName, size: 11))
                .foregroundColor(themeManager.bodyTextColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(themeManager.cardBackground.opacity(0.75), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(themeManager.cardBorder, lineWidth: 1)
                )

            Text(product.name)
                .font(.custom(themeManager.titleFontName, size: 14))
                .foregroundColor(themeManager.titleTextColor)
                .lineLimit(2)
                .frame(minHeight: 38, alignment: .top)

            HStack(spacing: 6) {
                Text("₹\(Int(product.price))")
                    .font(.custom(themeManager.titleFontName, size: 14))
                    .foregroundColor(themeManager.titleTextColor)
                if product.originalPrice > product.price {
                    Text("₹\(Int(product.originalPrice))")
                        .font(.custom(themeManager.bodyFontName, size: 11))
                        .foregroundColor(themeManager.bodyTextColor)
                        .strikethrough()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius, style: .continuous)
                .fill(themeManager.cardBackground.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: themeManager.cardCornerRadius, style: .continuous)
                .stroke(themeManager.cardBorder, lineWidth: 1)
        )
        .shadow(color: themeManager.cardBorder.opacity(themeManager.cardShadowOpacity), radius: 10, y: 6)
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
