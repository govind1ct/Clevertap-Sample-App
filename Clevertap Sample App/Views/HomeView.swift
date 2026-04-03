import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var themeManager: ThemeManager

    @StateObject private var productService = ProductService()
    @StateObject private var productExperienceService = CleverTapProductExperiencesService.shared
    @StateObject private var profileService = ProfileService()
    @StateObject private var heroBannerService = HeroBannerService()

    @Namespace private var productTransitionNamespace

    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var showingCart = false
    @State private var currentHeroBannerIndex = 0
    @State private var selectedHeroProduct: Product?
    @State private var navigatedProduct: Product?
    @State private var animateGreeting = false
    @State private var bannerProgress: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var recentSearches: [String] = ["Bracelets", "Rings", "Energy jewelry"]
    @State private var wishlistedProductIDs: Set<String> = []
    @State private var fabExpanded = false
    @FocusState private var isSearchFieldFocused: Bool

    private let heroAutoScrollIntervalNanoseconds: UInt64 = 4_500_000_000
    private let heroAutoScrollDuration: Double = 4.5
    private let trendingSearches = ["🔥 Rings", "💍 Wedding", "✨ Minimal", "🎁 Gifts"]

    private enum HomeSection: Hashable {
        case spotlight
        case collection
    }

    private var categories: [String] {
        ["All"] + ProductCategory.allCases.map { $0.rawValue.capitalized }
    }

    private var filteredProducts: [Product] {
        let baseProducts = selectedCategory == "All"
            ? productService.products
            : productService.products.filter { $0.category.capitalized == selectedCategory }

        let searchedProducts: [Product]
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            searchedProducts = baseProducts
        } else {
            searchedProducts = baseProducts.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.category.localizedCaseInsensitiveContains(searchText) ||
                product.searchKeywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
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

    private var orderedSections: [HomeSection] {
        var sections: [HomeSection] = []
        let shouldPrioritizeSpotlight = productExperienceService.showHomeHeaderBadge && !productExperienceService.homeHeaderBadge.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if shouldPrioritizeSpotlight, productExperienceService.showFeaturedSection, !featuredProducts.isEmpty {
            sections.append(.spotlight)
        }
        if !shouldPrioritizeSpotlight, productExperienceService.showFeaturedSection, !featuredProducts.isEmpty {
            sections.append(.spotlight)
        }
        sections.append(.collection)
        return sections
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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }

    private var recommendationsTitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Because you viewed \(searchText)"
        }
        if selectedCategory != "All" {
            return "Recommended in \(selectedCategory)"
        }
        if let firstTag = featuredProducts.first?.resolvedCampaignTags.first, !firstTag.isEmpty {
            return "Because you viewed \(firstTag)"
        }

        let configured = productExperienceService.featuredSectionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return configured.isEmpty ? productExperienceService.homeHeaderTitle : configured
    }

    private var recommendationsSubtitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Because you searched \(searchText)"
        }
        if selectedCategory != "All" {
            return "Because you explored \(selectedCategory)"
        }
        return productExperienceService.homeHeaderSubtitle
    }

    private var collectionTitle: String {
        if selectedCategory != "All" {
            return selectedCategory
        }
        return productExperienceService.homeHeaderTitle
    }

    private var collectionSubtitle: String {
        if let firstTag = featuredProducts.first?.resolvedCampaignTags.first, !firstTag.isEmpty {
            return "Because you viewed \(firstTag)"
        }
        return "Curated by product experiences"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            backgroundView

            ScrollView(showsIndicators: false) {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: HomeScrollOffsetKey.self, value: proxy.frame(in: .named("homeScroll")).minY)
                }
                .frame(height: 0)

                VStack(spacing: 22) {
                    premiumHeroSection
                    smartSearchSection
                    campaignRunwaySection
                    HomeNativeDisplayView()
                    dynamicContentSections
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 140)
            }
            .coordinateSpace(name: "homeScroll")
            .onPreferenceChange(HomeScrollOffsetKey.self) { value in
                scrollOffset = value
            }
            .refreshable {
                productService.fetchProducts()
                productExperienceService.fetchVariables()
                heroBannerService.fetchBanners()
            }

            floatingActionButton
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
        .navigationDestination(
            isPresented: Binding(
                get: { navigatedProduct != nil },
                set: { newValue in
                    if !newValue {
                        navigatedProduct = nil
                    }
                }
            )
        ) {
            if let product = navigatedProduct {
                ProductDetailView(product: product)
            }
        }
        .onAppear {
            productService.fetchProducts()
            productExperienceService.fetchVariables()
            heroBannerService.fetchBanners()
            profileService.fetchUserProfile { _ in }
            CleverTapService.shared.trackScreenViewed(screenName: "Home")
            withAnimation(.spring(response: 0.7, dampingFraction: 0.84)) {
                animateGreeting = true
            }
            restartBannerProgress()
        }
        .onChange(of: currentHeroBannerIndex) { _, _ in
            restartBannerProgress()
        }
        .onChange(of: activeHeroBanners.count) { _, newCount in
            if newCount == 0 {
                currentHeroBannerIndex = 0
            } else if currentHeroBannerIndex >= newCount {
                currentHeroBannerIndex = 0
            }
            restartBannerProgress()
        }
        .task(id: activeHeroBanners.map { $0.id ?? $0.title }.joined(separator: "|")) {
            guard activeHeroBanners.count > 1 else { return }

            restartBannerProgress()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: heroAutoScrollIntervalNanoseconds)
                guard !Task.isCancelled else { break }
                guard activeHeroBanners.count > 1 else { break }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        currentHeroBannerIndex = (currentHeroBannerIndex + 1) % activeHeroBanners.count
                    }
                }
            }
        }
    }
}

private extension HomeView {
    var premiumHeroSection: some View {
        HomeHeroSection(
            greetingText: greetingText,
            firstName: firstName,
            title: productExperienceService.homeHeaderTitle,
            subtitle: productExperienceService.homeHeaderSubtitle,
            profileName: profileService.userProfile.name,
            profilePhotoURL: profileService.userProfile.photoURL,
            offerCount: activeHeroBanners.count,
            featuredCount: featuredProducts.count,
            cartCount: cartManager.itemCount,
            animateGreeting: animateGreeting,
            accentStart: accentStart,
            accentEnd: accentEnd,
            isDarkMode: isDarkMode,
            titleFontName: themeManager.titleFontName,
            bodyFontName: themeManager.bodyFontName,
            onResetOffers: {
                Haptics.soft()
                if !activeHeroBanners.isEmpty {
                    currentHeroBannerIndex = 0
                }
            },
            onViewCart: {
                Haptics.soft()
                showingCart = true
            }
        )
    }

    var smartSearchSection: some View {
        HomeSearchSection(
            categories: categories,
            selectedCategory: selectedCategory,
            accentStart: accentStart,
            primaryText: primaryText,
            secondaryText: secondaryText,
            headlineText: headlineText,
            categoryLabel: categoryLabel(for:),
            categoryIcon: categoryIcon(for:),
            onReset: {
                Haptics.soft()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                    selectedCategory = "All"
                    searchText = ""
                }
            },
            onSelectCategory: { category in
                Haptics.soft()
                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    selectedCategory = category
                    searchText = ""
                }
            }
        )
    }

    var campaignRunwaySection: some View {
        HomeCampaignSection(
            banners: activeHeroBanners,
            currentIndex: $currentHeroBannerIndex,
            bannerProgress: bannerProgress,
            isDarkMode: isDarkMode,
            titleFontName: themeManager.titleFontName,
            bodyFontName: themeManager.bodyFontName,
            accentStart: accentStart,
            accentEnd: accentEnd,
            surfaceBorder: surfaceBorder,
            onBannerTap: { banner in
                Haptics.soft()
                handleHeroBannerTap(banner)
            }
        )
    }

    @ViewBuilder
    var dynamicContentSections: some View {
        if isInitialLoading {
            loadingSection
        } else if let errorMessage = productService.errorMessage, productService.products.isEmpty {
            errorSection(message: errorMessage)
        } else if filteredProducts.isEmpty {
            emptySection
        } else {
            ForEach(orderedSections, id: \.self) { section in
                switch section {
                case .spotlight:
                    spotlightSection
                case .collection:
                    collectionSection
                }
            }
        }
    }

    var spotlightSection: some View {
        HomeSpotlightSection(
            products: featuredProducts,
            title: recommendationsTitle,
            subtitle: recommendationsSubtitle,
            scrollOffset: scrollOffset,
            namespace: productTransitionNamespace,
            badge: productBadge(for:),
            socialProof: socialProof(for:),
            isWishlisted: isWishlisted(_:),
            onToggleWishlist: toggleWishlist(for:),
            onOpenProduct: { product in
                Haptics.soft()
                navigatedProduct = product
            },
            onQuickView: { product in
                Haptics.soft()
                selectedHeroProduct = product
            },
            onQuickBuy: quickBuy(_:)
        )
    }

    var collectionSection: some View {
        HomeCollectionSection(
            products: filteredProducts,
            selectedCategory: selectedCategory,
            subtitle: collectionSubtitle,
            scrollOffset: scrollOffset,
            namespace: productTransitionNamespace,
            badge: productBadge(for:),
            socialProof: socialProof(for:),
            isWishlisted: isWishlisted(_:),
            onToggleWishlist: toggleWishlist(for:),
            onOpenProduct: { product in
                Haptics.soft()
                navigatedProduct = product
            },
            onQuickView: { product in
                Haptics.soft()
                selectedHeroProduct = product
            },
            onQuickBuy: quickBuy(_:)
        )
    }

    var floatingActionButton: some View {
        VStack(alignment: .trailing, spacing: 12) {
            if fabExpanded {
                floatingShortcut(title: "Quick Buy", systemImage: "bag.fill") {
                    Haptics.soft()
                    isSearchFieldFocused = true
                }
                floatingShortcut(title: "Offers", systemImage: "tag.fill") {
                    Haptics.soft()
                    if !activeHeroBanners.isEmpty {
                        currentHeroBannerIndex = 0
                    }
                }
                floatingShortcut(title: "Rewards", systemImage: "gift.fill") {
                    Haptics.soft()
                }
            }

            Button {
                Haptics.tap()
                withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                    fabExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: fabExpanded ? "xmark" : "sparkles")
                        .font(.headline.weight(.bold))
                    Text(fabExpanded ? "Close" : "Quick Shop")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [accentStart, accentEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: shadowColor.opacity(0.18), radius: 16, y: 10)
                .scaleEffect(fabExpanded ? 1.03 : 1)
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 22)
        .padding(.bottom, 28)
    }

    var backgroundView: some View {
        LinearGradient(
            colors: homeBackgroundGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Rectangle()
                .fill(isDarkMode ? Color.black.opacity(0.18) : Color.white.opacity(0.08))
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(accentStart.opacity(isDarkMode ? 0.22 : 0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 84)
                .offset(x: -110, y: -180 + (scrollOffset * 0.16))
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(accentEnd.opacity(isDarkMode ? 0.20 : 0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 86)
                .offset(x: 110, y: -120 - (scrollOffset * 0.10))
        }
        .overlay(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 110, style: .continuous)
                .fill(Color.white.opacity(isDarkMode ? 0.02 : 0.16))
                .frame(width: 320, height: 180)
                .blur(radius: 54)
                .rotationEffect(.degrees(-14))
                .offset(x: -70, y: 130 + (scrollOffset * 0.06))
        }
        .ignoresSafeArea()
    }

    var heroBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                accentStart.opacity(isDarkMode ? 0.16 : 0.12),
                surfaceFill.opacity(0.92),
                accentEnd.opacity(isDarkMode ? 0.14 : 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var searchBackground: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.62)
    }

    var searchBorder: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.34)
    }

    var controlPanelFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.72)
    }

    var loadingSection: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.38))
                .frame(height: 260)
                .redacted(reason: .placeholder)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.38))
                        .frame(height: 220)
                        .redacted(reason: .placeholder)
                }
            }
        }
        .padding(.top, 8)
    }

    func errorSection(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.orange)
                .frame(width: 74, height: 74)
                .background(Color.orange.opacity(0.14), in: Circle())

            Text("Storefront unavailable")
                .font(.custom(themeManager.titleFontName, size: 24))
                .foregroundStyle(headlineText)

            Text(message)
                .font(.custom(themeManager.bodyFontName, size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Button {
                Haptics.tap()
                productService.fetchProducts()
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(selectedChipText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [accentStart, accentEnd], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(controlPanelFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    var emptySection: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(accentStart)
                .frame(width: 74, height: 74)
                .background(accentStart.opacity(0.14), in: Circle())

            Text("Nothing matches right now")
                .font(.custom(themeManager.titleFontName, size: 24))
                .foregroundStyle(headlineText)

            Text("Try a trending search or reset the filters to explore the latest picks.")
                .font(.custom(themeManager.bodyFontName, size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Button {
                Haptics.soft()
                if let firstTrending = trendingSearches.first {
                    let cleaned = cleanedTrendText(from: firstTrending)
                    searchText = cleaned
                    submitSearch(cleaned)
                }
            } label: {
                Text("Explore Trending")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(selectedChipText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [accentStart, accentEnd], startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(controlPanelFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
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

    func categoryLabel(for category: String) -> String {
        category == "All" ? "All Items" : category
    }

    func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "all":
            return "square.grid.2x2.fill"
        case "ring", "rings":
            return "sparkle"
        case "bracelet", "bracelets":
            return "link"
        case "pendant", "pendants":
            return "drop.fill"
        case "mala", "malas":
            return "leaf.fill"
        case "stone", "stones":
            return "diamond.fill"
        case "other":
            return "square.stack.3d.up.fill"
        default:
            return "tag.fill"
        }
    }

    func cleanedTrendText(from value: String) -> String {
        value
            .replacingOccurrences(of: "🔥 ", with: "")
            .replacingOccurrences(of: "💍 ", with: "")
            .replacingOccurrences(of: "✨ ", with: "")
            .replacingOccurrences(of: "🎁 ", with: "")
    }

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

    func colorFromHex(_ hex: String) -> Color? {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard normalized.count == 6, let value = Int(normalized, radix: 16) else { return nil }

        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }

    func submitSearch(_ value: String) {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        if let idx = recentSearches.firstIndex(of: cleaned) {
            recentSearches.remove(at: idx)
        }
        recentSearches.insert(cleaned, at: 0)
        recentSearches = Array(recentSearches.prefix(5))
    }

    func restartBannerProgress() {
        bannerProgress = 0
        guard activeHeroBanners.count > 1 else { return }
        withAnimation(.linear(duration: heroAutoScrollDuration)) {
            bannerProgress = 1
        }
    }

    func toggleWishlist(for product: Product) {
        Haptics.soft()
        guard let key = product.id ?? product.name as String? else { return }
        if wishlistedProductIDs.contains(key) {
            wishlistedProductIDs.remove(key)
        } else {
            wishlistedProductIDs.insert(key)
        }
    }

    func isWishlisted(_ product: Product) -> Bool {
        let key = product.id ?? product.name
        return wishlistedProductIDs.contains(key)
    }

    func quickBuy(_ product: Product) {
        Haptics.success()
        cartManager.addToCart(product)
    }

    func productBadge(for product: Product) -> String {
        if product.resolvedMerchandisingPriority >= 8 { return "Premium" }
        if product.isNewLaunchActive { return "Trending" }
        if product.isFeaturedActive { return "Fast Selling" }
        return "Curated"
    }

    func socialProof(for product: Product) -> String {
        let base = abs((product.id ?? product.name).hashValue % 1800) + 180
        let formatted: String
        if base >= 1000 {
            formatted = String(format: "%.1fk", Double(base) / 1000.0)
        } else {
            formatted = "\(base)"
        }
        return "🔥 \(formatted) bought today"
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
            submitSearch(campaignTag)
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
            submitSearch(query)
        }
    }

    func floatingShortcut(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(primaryText)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale))
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
}

private struct HomeScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(CartManager())
            .environmentObject(ThemeManager.shared)
    }
}
