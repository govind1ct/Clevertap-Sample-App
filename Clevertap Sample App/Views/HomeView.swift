import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var authViewModel: AuthViewModel

    @StateObject private var productService = ProductService()
    @StateObject private var productExperienceService = CleverTapProductExperiencesService.shared
    @StateObject private var profileService = ProfileService()
    @StateObject private var heroBannerService = HeroBannerService()
    @EnvironmentObject private var themeManager: ThemeManager
    @Namespace private var productTransitionNamespace

    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var showingCart = false
    @State private var currentHeroBannerIndex = 0
    @State private var selectedHeroProduct: Product?
    @State private var isSearchExpanded = false
    @FocusState private var isSearchFieldFocused: Bool
    private let heroAutoScrollIntervalNanoseconds: UInt64 = 4_500_000_000

    private var categories: [String] {
        ["All"] + ProductCategory.allCases.map { $0.rawValue.capitalized }
    }

    private var filteredProducts: [Product] {
        let baseProducts = selectedCategory == "All"
            ? productService.products
            : productService.products.filter { $0.category.capitalized == selectedCategory }

        let searchedProducts: [Product]
        if searchText.isEmpty {
            searchedProducts = baseProducts
        } else {
            searchedProducts = baseProducts.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        return searchedProducts.sorted { lhs, rhs in
            let lhsHomeSlot = lhs.resolvedHomePlacementSlot ?? Int.max
            let rhsHomeSlot = rhs.resolvedHomePlacementSlot ?? Int.max
            if lhsHomeSlot != rhsHomeSlot {
                return lhsHomeSlot < rhsHomeSlot
            }
            if lhs.resolvedCategoryPinned != rhs.resolvedCategoryPinned {
                return lhs.resolvedCategoryPinned && !rhs.resolvedCategoryPinned
            }
            if lhs.resolvedCategorySortPriority != rhs.resolvedCategorySortPriority {
                return lhs.resolvedCategorySortPriority > rhs.resolvedCategorySortPriority
            }
            if lhs.resolvedMerchandisingPriority != rhs.resolvedMerchandisingPriority {
                return lhs.resolvedMerchandisingPriority > rhs.resolvedMerchandisingPriority
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private var featuredProducts: [Product] {
        Array(
            filteredProducts
                .filter { $0.isFeaturedActive }
                .sorted(by: featuredSortOrder)
                .prefix(productExperienceService.maxFeaturedProducts)
        )
    }

    private var activeHeroBanners: [HeroBanner] {
        heroBannerService.activeBanners
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
                    if !activeHeroBanners.isEmpty {
                        heroBannerSection
                    }
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
        .sheet(item: $selectedHeroProduct) { product in
            NavigationStack {
                ProductDetailView(product: product)
            }
        }
        .onAppear {
            productService.fetchProducts()
            productExperienceService.fetchVariables()
            heroBannerService.fetchBanners()
            profileService.fetchUserProfile { _ in }
            CleverTapService.shared.trackScreenViewed(screenName: "Home")
        }
        .onChange(of: activeHeroBanners.count) { _, newCount in
            if newCount == 0 {
                currentHeroBannerIndex = 0
            } else if currentHeroBannerIndex >= newCount {
                currentHeroBannerIndex = 0
            }
        }
        .task(id: activeHeroBanners.map { $0.id ?? $0.title }.joined(separator: "|")) {
            guard activeHeroBanners.count > 1 else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: heroAutoScrollIntervalNanoseconds)
                guard !Task.isCancelled else { break }
                guard activeHeroBanners.count > 1 else { break }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentHeroBannerIndex = (currentHeroBannerIndex + 1) % activeHeroBanners.count
                    }
                }
            }
        }
    }
}

private extension HomeView {
    func featuredSortOrder(_ lhs: Product, _ rhs: Product) -> Bool {
        let lhsHomeSlot = lhs.resolvedHomePlacementSlot ?? Int.max
        let rhsHomeSlot = rhs.resolvedHomePlacementSlot ?? Int.max
        if lhsHomeSlot != rhsHomeSlot {
            return lhsHomeSlot < rhsHomeSlot
        }
        if lhs.resolvedMerchandisingPriority != rhs.resolvedMerchandisingPriority {
            return lhs.resolvedMerchandisingPriority > rhs.resolvedMerchandisingPriority
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}

private extension HomeView {
    var heroBannerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            TabView(selection: $currentHeroBannerIndex) {
                ForEach(Array(activeHeroBanners.enumerated()), id: \.element.id) { index, banner in
                    HeroBannerCard(
                        banner: banner,
                        isDarkMode: isDarkMode,
                        titleFontName: themeManager.titleFontName,
                        bodyFontName: themeManager.bodyFontName,
                        onPrimaryAction: {
                            handleHeroBannerTap(banner)
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 250)

            if activeHeroBanners.count > 1 {
                HStack(spacing: 8) {
                    ForEach(Array(activeHeroBanners.indices), id: \.self) { index in
                        Capsule()
                            .fill(index == currentHeroBannerIndex ? accentStart : surfaceBorder.opacity(0.8))
                            .frame(width: index == currentHeroBannerIndex ? 22 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.22), value: currentHeroBannerIndex)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

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
        VStack(alignment: .leading, spacing: activeHeroBanners.isEmpty ? 18 : 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: activeHeroBanners.isEmpty ? 8 : 6) {
                    HStack(spacing: 8) {
                        Text(activeHeroBanners.isEmpty ? currentDateLabel.uppercased() : "TODAY • \(currentDateLabel.uppercased())")
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

                    if activeHeroBanners.isEmpty {
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
                    } else {
                        Text("Good to see you, \(firstName)")
                            .font(.custom(themeManager.titleFontName, size: 24))
                            .foregroundStyle(headlineText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Fresh picks, active offers, and your cart snapshot are ready below.")
                            .font(.custom(themeManager.bodyFontName, size: 13))
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isSearchExpanded.toggle()
                        }
                        if isSearchExpanded {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isSearchFieldFocused = true
                            }
                        } else {
                            isSearchFieldFocused = false
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(headlineText)
                            .frame(width: activeHeroBanners.isEmpty ? 48 : 44, height: activeHeroBanners.isEmpty ? 48 : 44)
                            .background(surfaceFill, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSearchExpanded ? accentStart.opacity(0.8) : surfaceBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingCart = true
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "cart.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(headlineText)
                                .frame(width: activeHeroBanners.isEmpty ? 48 : 44, height: activeHeroBanners.isEmpty ? 48 : 44)
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
            }

            HStack(spacing: 12) {
                summaryPill(icon: "shippingbox.fill", text: "\(filteredProducts.count) products")
                summaryPill(icon: "sparkles", text: selectedCategory)
                summaryPill(icon: "bag.fill", text: cartManager.itemCount == 0 ? "Cart empty" : "\(cartManager.itemCount) in cart")
            }
        }
        .padding(activeHeroBanners.isEmpty ? 20 : 18)
        .background(
            RoundedRectangle(cornerRadius: activeHeroBanners.isEmpty ? 28 : 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: activeHeroBanners.isEmpty
                            ? [
                                accentStart.opacity(isDarkMode ? 0.18 : 0.12),
                                accentEnd.opacity(isDarkMode ? 0.14 : 0.08),
                                surfaceFill
                            ]
                            : [
                                accentStart.opacity(isDarkMode ? 0.12 : 0.10),
                                surfaceFill,
                                accentEnd.opacity(isDarkMode ? 0.08 : 0.06)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: activeHeroBanners.isEmpty ? 28 : 24, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: activeHeroBanners.isEmpty ? 24 : 18, y: activeHeroBanners.isEmpty ? 14 : 10)
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
        Group {
            if isSearchExpanded || !searchText.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Search The Collection")
                                .font(.custom(themeManager.titleFontName, size: 18))
                                .foregroundStyle(headlineText)

                            Text(searchText.isEmpty ? "Find products, categories, and campaign picks faster." : "Showing results for \"\(searchText)\".")
                                .font(.custom(themeManager.bodyFontName, size: 12))
                                .foregroundStyle(secondaryText)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 10)

                        HStack(spacing: 8) {
                            if selectedCategory != "All" {
                                Text(selectedCategory)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(selectedChipText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            colors: [accentStart, accentEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: Capsule()
                                    )
                            }

                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    isSearchExpanded = false
                                    if searchText.isEmpty {
                                        isSearchFieldFocused = false
                                    }
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(headlineText)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(isDarkMode ? 0.10 : 0.72), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(headlineText)
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(isDarkMode ? 0.10 : 0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        TextField("Search products or categories", text: $searchText)
                            .textFieldStyle(.plain)
                            .submitLabel(.search)
                            .foregroundStyle(primaryText)
                            .focused($isSearchFieldFocused)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(headlineText)
                                    .frame(width: 30, height: 30)
                                    .background(Color.white.opacity(isDarkMode ? 0.10 : 0.72), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(isDarkMode ? 0.08 : 0.58))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(isDarkMode ? 0.08 : 0.36), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentStart.opacity(isDarkMode ? 0.10 : 0.08),
                                    surfaceFill,
                                    accentEnd.opacity(isDarkMode ? 0.08 : 0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(surfaceBorder, lineWidth: 1)
                )
                .shadow(color: shadowColor.opacity(0.7), radius: 16, y: 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    if isSearchExpanded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isSearchFieldFocused = true
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: isSearchExpanded)
    }

    var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Browse By Category")
                        .font(.custom(themeManager.titleFontName, size: 18))
                        .foregroundStyle(headlineText)

                    Text("Switch between all products and focused category views.")
                        .font(.custom(themeManager.bodyFontName, size: 12))
                        .foregroundStyle(secondaryText)
                }

                Spacer(minLength: 10)

                if selectedCategory != "All" {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategory = "All"
                        }
                    } label: {
                        Text("Reset")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(headlineText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(surfaceFill, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(surfaceBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: categoryIcon(for: category))
                                    .font(.caption.weight(.bold))

                                Text(categoryLabel(for: category))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(selectedCategory == category ? selectedChipText : headlineText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(categoryChipBackground(for: category), in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(categoryChipBorder(for: category), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
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
            AnyShapeStyle(
                LinearGradient(
                    colors: [surfaceFill, Color.white.opacity(isDarkMode ? 0.04 : 0.38)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }

    func categoryChipBorder(for category: String) -> Color {
        selectedCategory == category ? .clear : surfaceBorder
    }

    func categoryLabel(for category: String) -> String {
        category == "All" ? "All Items" : category
    }

    func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "all":
            return "square.grid.2x2.fill"
        case "ring", "rings":
            return "sparkle"
        case "necklace", "necklaces":
            return "circle.hexagongrid.fill"
        case "bracelet", "bracelets":
            return "link"
        case "earring", "earrings":
            return "seal.fill"
        case "pendant", "pendants":
            return "drop.fill"
        default:
            return "tag.fill"
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

    func handleHeroBannerTap(_ banner: HeroBanner) {
        CleverTapService.shared.trackEvent(
            "Hero Banner Tapped",
            withProps: [
                "title": banner.title,
                "banner_id": banner.id ?? "",
                "offer_label": banner.offerLabel ?? "",
                "campaign_tag": banner.campaignTag ?? ""
            ]
        )

        if let linkedProductID = banner.linkedProductID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !linkedProductID.isEmpty,
           let matchedProduct = productService.products.first(where: { $0.id == linkedProductID }) {
            selectedHeroProduct = matchedProduct
            return
        }

        if let campaignTag = banner.campaignTag?.trimmingCharacters(in: .whitespacesAndNewlines),
           !campaignTag.isEmpty {
            selectedCategory = "All"
            searchText = campaignTag
            return
        }

        let deepLinkValue = banner.ctaDeepLink?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !deepLinkValue.isEmpty else { return }

        if deepLinkValue == "cart" {
            showingCart = true
            return
        }

        if deepLinkValue == "products" || deepLinkValue == "all" || deepLinkValue == "catalog" {
            selectedCategory = "All"
            searchText = ""
            return
        }

        if deepLinkValue.hasPrefix("category:") {
            let rawCategory = String(deepLinkValue.dropFirst("category:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let matchedCategory = categories.first(where: { $0.lowercased() == rawCategory.lowercased() }) {
                selectedCategory = matchedCategory
                searchText = ""
            }
            return
        }

        if deepLinkValue.hasPrefix("search:") {
            let query = String(deepLinkValue.dropFirst("search:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            selectedCategory = "All"
            searchText = query
        }
    }
}

private struct HeroBannerCard: View {
    let banner: HeroBanner
    let isDarkMode: Bool
    let titleFontName: String
    let bodyFontName: String
    let onPrimaryAction: () -> Void

    private var hasDestination: Bool {
        let linkedProductID = banner.linkedProductID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let campaignTag = banner.campaignTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let deepLink = banner.ctaDeepLink?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !linkedProductID.isEmpty || !campaignTag.isEmpty || !deepLink.isEmpty
    }

    private var backgroundStart: Color {
        colorFromHex(banner.backgroundHex) ?? Color("CleverTapPrimary")
    }

    private var backgroundEnd: Color {
        colorFromHex(banner.accentHex) ?? Color("CleverTapSecondary")
    }

    private var cardTitleColor: Color {
        .white
    }

    private var cardBodyColor: Color {
        Color.white.opacity(0.82)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [backgroundStart, backgroundEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                AppAsyncImage(urlString: banner.resolvedMobileImageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(.clear)
                    }
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(isDarkMode ? 0.18 : 0.10),
                            Color.black.opacity(0.50)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    if let offerLabel = banner.offerLabel, !offerLabel.isEmpty {
                        heroChip(title: offerLabel)
                    }

                    if let offerCode = banner.offerCode, !offerCode.isEmpty {
                        heroChip(title: offerCode)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 8) {
                    Text(banner.title)
                        .font(.custom(titleFontName, size: 28))
                        .foregroundStyle(cardTitleColor)
                        .lineLimit(2)

                    Text(banner.subtitle)
                        .font(.custom(bodyFontName, size: 14))
                        .foregroundStyle(cardBodyColor)
                        .lineLimit(3)
                }

                if let ctaText = banner.ctaText, !ctaText.isEmpty {
                    HStack(spacing: 8) {
                        Text(ctaText)
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(backgroundStart)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white, in: Capsule())
                }
            }
            .padding(22)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(isDarkMode ? 0.10 : 0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onTapGesture {
            guard hasDestination else { return }
            onPrimaryAction()
        }
        .shadow(color: Color.black.opacity(isDarkMode ? 0.24 : 0.12), radius: 22, y: 12)
    }

    private func heroChip(title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.16), in: Capsule())
    }

    private func colorFromHex(_ hex: String?) -> Color? {
        guard let hex else { return nil }
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard normalized.count == 6, let value = Int(normalized, radix: 16) else { return nil }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
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
