import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            colors: homeBackgroundGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Rectangle()
                .fill(isDarkMode ? Color.black.opacity(0.20) : Color.white.opacity(0.18))
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(accentStart.opacity(isDarkMode ? 0.32 : 0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 52)
                .offset(x: -80, y: -120)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(accentEnd.opacity(isDarkMode ? 0.28 : 0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 54)
                .offset(x: 90, y: 120)
        }
        .ignoresSafeArea()
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(currentDateLabel.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(secondaryText)

                        if productExperienceService.showHomeHeaderBadge,
                           !productExperienceService.homeHeaderBadge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(productExperienceService.homeHeaderBadge.uppercased())
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(primaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(accentStart.opacity(isDarkMode ? 0.22 : 0.14), in: Capsule())
                        }
                    }

                    Text("Good to see you, \(firstName)")
                        .font(.custom(themeManager.bodyFontName, size: 14))
                        .foregroundStyle(secondaryText)

                    Text(productExperienceService.homeHeaderTitle)
                        .font(.custom(themeManager.titleFontName, size: 34))
                        .foregroundStyle(headlineText)
                        .lineLimit(2)

                    Text(productExperienceService.homeHeaderSubtitle)
                        .font(.custom(themeManager.bodyFontName, size: 15))
                        .foregroundStyle(secondaryText)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                Button {
                    showingCart = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(headlineText)
                            .frame(width: 52, height: 52)
                            .background(surfaceFill, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(surfaceBorder, lineWidth: 1)
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

            HStack(spacing: 12) {
                summaryPill(icon: "shippingbox.fill", text: "\(filteredProducts.count) products")
                summaryPill(icon: "sparkles", text: selectedCategory)
                summaryPill(icon: "bag.fill", text: cartManager.itemCount == 0 ? "Cart empty" : "\(cartManager.itemCount) in cart")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            accentStart.opacity(isDarkMode ? 0.18 : 0.12),
                            accentEnd.opacity(isDarkMode ? 0.14 : 0.08),
                            surfaceFill
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: 24, y: 14)
    }

    func summaryPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(headlineText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(surfaceFill.opacity(isDarkMode ? 0.82 : 0.72), in: Capsule())
        .overlay(
            Capsule()
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find your next piece")
                .font(.custom(themeManager.bodyFontName, size: 13))
                .foregroundStyle(secondaryText)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(secondaryText)

                TextField("Search products or categories", text: $searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .foregroundStyle(primaryText)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(secondaryText)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(surfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
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
                            .foregroundStyle(selectedCategory == category ? selectedChipText : secondaryText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
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
                    colors: [accentStart, accentEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            AnyShapeStyle(surfaceFill)
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
            HomeSectionHeader(
                eyebrow: "Editor Picks",
                title: productExperienceService.featuredSectionTitle,
                detail: "\(featuredProducts.count) curated"
            )

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
            HomeSectionHeader(
                eyebrow: selectedCategory == "All" ? "Collection" : selectedCategory,
                title: "All Products",
                detail: "\(filteredProducts.count) items"
            )

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

    var isDarkMode: Bool {
        colorScheme == .dark
    }

    var accentStart: Color {
        colorFromHex(productExperienceService.homeThemeGradientStart) ?? Color("CleverTapPrimary")
    }

    var accentEnd: Color {
        colorFromHex(productExperienceService.homeThemeGradientEnd) ?? Color("CleverTapSecondary")
    }

    var surfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.82)
    }

    var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.90)
    }

    var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.72) : Color.black.opacity(0.58)
    }

    var headlineText: Color {
        isDarkMode ? .white : Color.black.opacity(0.96)
    }

    var shadowColor: Color {
        Color.black.opacity(isDarkMode ? 0.24 : 0.10)
    }

    var selectedChipText: Color {
        isDarkMode ? Color.black.opacity(0.88) : .white
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

private struct HomeSectionHeader: View {
    let eyebrow: String
    let title: String
    let detail: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.62) : Color.black.opacity(0.45))
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : Color.black.opacity(0.92))
            }

            Spacer()

            Text(detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.66) : Color.black.opacity(0.52))
        }
    }
}

private struct FeaturedProductCard: View {
    let product: Product
    @Environment(\.colorScheme) private var colorScheme
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
                colors: [.clear, Color.black.opacity(colorScheme == .dark ? 0.82 : 0.68)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26))

            VStack(alignment: .leading, spacing: 7) {
                Text("FEATURED")
                    .font(.custom(themeManager.bodyFontName, size: 11))
                    .foregroundStyle(colorScheme == .dark ? .white : Color.black.opacity(0.88))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                Text(product.name)
                    .font(.custom(themeManager.titleFontName, size: 20))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(product.shortDescription ?? product.category.capitalized)
                    .font(.custom(themeManager.bodyFontName, size: 12))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("₹\(Int(product.price))")
                        .font(.custom(themeManager.titleFontName, size: 16))
                        .foregroundStyle(.white)
                    if product.originalPrice > product.price {
                        Text("₹\(Int(product.originalPrice))")
                            .font(.custom(themeManager.bodyFontName, size: 11))
                            .strikethrough()
                            .foregroundStyle(Color.white.opacity(0.68))
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(16)
        }
        .frame(width: 290, height: 350)
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.14), radius: 18, y: 12)
    }
}

private struct GridProductCard: View {
    let product: Product
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            productImage
            categoryRow
            productTitle
            priceRow
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .shadow(color: cardShadow, radius: 12, y: 8)
    }

    private var productImage: some View {
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
    }

    private var categoryRow: some View {
        HStack {
            Text(product.category.capitalized)
                .font(.custom(themeManager.bodyFontName, size: 11))
                .foregroundStyle(categoryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryBackground, in: Capsule())

            Spacer(minLength: 0)

            if product.isFeatured {
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(Color.orange)
            }
        }
    }

    private var productTitle: some View {
        Text(product.name)
            .font(.custom(themeManager.titleFontName, size: 14))
            .foregroundStyle(titleText)
            .lineLimit(2)
            .frame(minHeight: 38, alignment: .top)
    }

    private var priceRow: some View {
        HStack(spacing: 6) {
            Text("₹\(Int(product.price))")
                .font(.custom(themeManager.titleFontName, size: 14))
                .foregroundStyle(titleText)

            if product.originalPrice > product.price {
                Text("₹\(Int(product.originalPrice))")
                    .font(.custom(themeManager.bodyFontName, size: 11))
                    .foregroundStyle(secondaryPriceText)
                    .strikethrough()
            }
        }
    }

    private var categoryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : Color.black.opacity(0.55)
    }

    private var categoryBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    private var titleText: Color {
        colorScheme == .dark ? .white : Color.black.opacity(0.92)
    }

    private var secondaryPriceText: Color {
        colorScheme == .dark ? Color.white.opacity(0.62) : Color.black.opacity(0.46)
    }

    private var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.82)
    }

    private var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var cardShadow: Color {
        Color.black.opacity(colorScheme == .dark ? 0.20 : 0.08)
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
