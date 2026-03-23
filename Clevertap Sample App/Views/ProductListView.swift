import SwiftUI

struct ProductListView: View {
    @StateObject private var productService = ProductService()
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var lastSearchText = ""
    @State private var selectedCategory: String = "All"
    @State private var showingFilters = false
    @State private var sortOption: SortOption = .name
    @State private var viewMode: ViewMode = .grid
    @State private var showOnlyDiscounts = false
    @State private var showNewLaunches = false
    @State private var minPriceFilter: Double = 0
    @State private var maxPriceFilter: Double = 0
    @State private var availableMinPrice: Double = 0
    @State private var availableMaxPrice: Double = 0

    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"

        var systemImage: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "rectangle.grid.1x2"
            }
        }
    }

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case priceLow = "Price: Low to High"
        case priceHigh = "Price: High to Low"
        case newest = "Newest First"

        var systemImage: String {
            switch self {
            case .name: return "textformat.abc"
            case .priceLow: return "arrow.up.circle"
            case .priceHigh: return "arrow.down.circle"
            case .newest: return "clock"
            }
        }
    }

    private let categories = ["All"] + ProductCategory.allCases.map { $0.rawValue.capitalized }

    private var filteredProducts: [Product] {
        var products = productService.products

        if selectedCategory != "All" {
            products = products.filter { $0.category.capitalized == selectedCategory }
        }

        if showOnlyDiscounts {
            products = products.filter { $0.originalPrice > $0.price }
        }

        if showNewLaunches {
            products = products.filter { $0.isNewLaunchActive }
        }

        if maxPriceFilter > 0 {
            products = products.filter { $0.price >= minPriceFilter && $0.price <= maxPriceFilter }
        }

        if !searchText.isEmpty {
            products = products.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.searchKeywords.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }

        switch sortOption {
        case .name:
            products = products.sorted(by: defaultCatalogOrder)
        case .priceLow:
            products = products.sorted { lhs, rhs in
                if lhs.resolvedCategoryPinned != rhs.resolvedCategoryPinned {
                    return lhs.resolvedCategoryPinned && !rhs.resolvedCategoryPinned
                }
                if lhs.price != rhs.price {
                    return lhs.price < rhs.price
                }
                if lhs.resolvedCategorySortPriority != rhs.resolvedCategorySortPriority {
                    return lhs.resolvedCategorySortPriority > rhs.resolvedCategorySortPriority
                }
                return lhs.resolvedMerchandisingPriority > rhs.resolvedMerchandisingPriority
            }
        case .priceHigh:
            products = products.sorted { lhs, rhs in
                if lhs.resolvedCategoryPinned != rhs.resolvedCategoryPinned {
                    return lhs.resolvedCategoryPinned && !rhs.resolvedCategoryPinned
                }
                if lhs.price != rhs.price {
                    return lhs.price > rhs.price
                }
                if lhs.resolvedCategorySortPriority != rhs.resolvedCategorySortPriority {
                    return lhs.resolvedCategorySortPriority > rhs.resolvedCategorySortPriority
                }
                return lhs.resolvedMerchandisingPriority > rhs.resolvedMerchandisingPriority
            }
        case .newest:
            products = products.sorted { lhs, rhs in
                if lhs.resolvedCategoryPinned != rhs.resolvedCategoryPinned {
                    return lhs.resolvedCategoryPinned && !rhs.resolvedCategoryPinned
                }
                if lhs.isNewLaunchActive != rhs.isNewLaunchActive {
                    return lhs.isNewLaunchActive && !rhs.isNewLaunchActive
                }
                if lhs.resolvedCategorySortPriority != rhs.resolvedCategorySortPriority {
                    return lhs.resolvedCategorySortPriority > rhs.resolvedCategorySortPriority
                }
                if lhs.resolvedMerchandisingPriority != rhs.resolvedMerchandisingPriority {
                    return lhs.resolvedMerchandisingPriority > rhs.resolvedMerchandisingPriority
                }
                return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
            }
        }

        return products
    }

    private func defaultCatalogOrder(_ lhs: Product, _ rhs: Product) -> Bool {
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

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var surfaceFill: AnyShapeStyle {
        if isDarkMode {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
        return AnyShapeStyle(Color.white.opacity(0.72))
    }

    private var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.9)
    }

    private func updatePriceBoundsIfNeeded() {
        let prices = productService.products.map { $0.price }
        guard let minPrice = prices.min(), let maxPrice = prices.max() else { return }

        availableMinPrice = minPrice
        availableMaxPrice = maxPrice

        if maxPriceFilter == 0 {
            minPriceFilter = minPrice
            maxPriceFilter = maxPrice
            return
        }

        minPriceFilter = max(minPriceFilter, minPrice)
        maxPriceFilter = min(maxPriceFilter, maxPrice)
        if minPriceFilter > maxPriceFilter {
            minPriceFilter = minPrice
            maxPriceFilter = maxPrice
        }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                headerSection
                searchAndSortSection
                categorySection

                Group {
                    if productService.isLoading {
                        loadingState
                    } else if let error = productService.errorMessage {
                        errorState(error)
                    } else if filteredProducts.isEmpty {
                        emptyState
                    } else if viewMode == .grid {
                        productGrid
                    } else {
                        productList
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            productService.fetchProducts()
            CleverTapService.shared.trackScreenViewed(screenName: "Product List")
        }
        .onChange(of: productService.products.count) { _, _ in
            updatePriceBoundsIfNeeded()
        }
        .sheet(isPresented: $showingFilters) {
            FiltersSheet(
                selectedCategory: $selectedCategory,
                sortOption: $sortOption,
                viewMode: $viewMode,
                showOnlyDiscounts: $showOnlyDiscounts,
                showNewLaunches: $showNewLaunches,
                minPrice: $minPriceFilter,
                maxPrice: $maxPriceFilter,
                availableMinPrice: availableMinPrice,
                availableMaxPrice: availableMaxPrice,
                categories: categories
            )
        }
    }
}

private extension ProductListView {
    var backgroundLayer: some View {
        LinearGradient(
            colors: isDarkMode
                ? [
                    Color(.systemBackground),
                    Color(red: 0.07, green: 0.09, blue: 0.13),
                    Color(.systemGroupedBackground)
                ]
                : [
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 0.99),
                    Color(.systemGroupedBackground)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.22 : 0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 30)
                .offset(x: -60, y: -70)
        }
        .ignoresSafeArea()
    }

    var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Discover")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("\(filteredProducts.count) products")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                showingFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    var searchAndSortSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search products", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        if !newValue.isEmpty && newValue != lastSearchText {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                if searchText == newValue && !newValue.isEmpty {
                                    CleverTapService.shared.trackSearchPerformed(
                                        searchTerm: newValue,
                                        resultCount: filteredProducts.count
                                    )
                                    lastSearchText = newValue
                                }
                            }
                        }
                    }

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
            .background(surfaceFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(surfaceBorder, lineWidth: 1)
            )

            HStack {
                Text("Sort")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            sortOption = option
                        } label: {
                            Label(option.rawValue, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: sortOption.systemImage)
                        Text(sortOption.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color("CleverTapPrimary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                }

                Picker("Layout", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .padding(.horizontal, 16)
    }

    var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedCategory == category
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(isDarkMode ? Color.white.opacity(0.09) : Color.white.opacity(0.7))
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    var productGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                ProductListNativeDisplayView()

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(filteredProducts.enumerated()), id: \.element.id) { index, product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            ProductTileCard(product: product) {
                                cartManager.addToCart(product)
                            }
                        }
                        .buttonStyle(.plain)

                        if (index + 1) % 6 == 0 && index < filteredProducts.count - 1 {
                            NativeDisplayContainerView(
                                location: "product_list_feed",
                                maxDisplayUnits: 1,
                                layout: .vertical
                            )
                            .gridCellColumns(2)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .refreshable {
            productService.fetchProducts()
            try? await Task.sleep(nanoseconds: 600_000_000)
        }
    }

    var productList: some View {
        List {
            ForEach(filteredProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    ProductRowCard(product: product) {
                        cartManager.addToCart(product)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            productService.fetchProducts()
            try? await Task.sleep(nanoseconds: 600_000_000)
        }
    }

    var loadingState: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.65))
                        .frame(height: 240)
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                productService.fetchProducts()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(.horizontal, 28)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No products found")
                .font(.headline)
            Text("Try another search or category")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !searchText.isEmpty || selectedCategory != "All" {
                Button("Clear Filters") {
                    searchText = ""
                    selectedCategory = "All"
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

private struct ProductTileCard: View {
    let product: Product
    let onAddToCart: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var hasDiscount: Bool {
        product.originalPrice > product.price
    }

    private var discountPercent: Int {
        guard hasDiscount else { return 0 }
        return Int(((product.originalPrice - product.price) / product.originalPrice) * 100)
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                AppAsyncImage(urlString: product.mainImageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(.secondarySystemBackground)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Button(action: onAddToCart) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color("CleverTapPrimary"), in: Circle())
                    }
                    .padding(8)
                }

                if hasDiscount {
                    Text("\(discountPercent)% OFF")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.red, in: Capsule())
                        .padding(8)
                }
            }

            HStack(spacing: 6) {
                Text(product.category.capitalized)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                if product.isFeaturedActive {
                    badgeLabel("FEATURED", color: .orange)
                } else if product.isNewLaunchActive {
                    badgeLabel("NEW", color: .green)
                }
            }

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .frame(minHeight: 36, alignment: .top)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("₹\(Int(product.price))")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color("CleverTapPrimary"))

                if hasDiscount {
                    Text("₹\(Int(product.originalPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .strikethrough()
                }
            }
        }
        .padding(10)
        .background(
            isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.76),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.9), lineWidth: 1)
        )
    }

    private func badgeLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(color)
    }
}

private struct ProductRowCard: View {
    let product: Product
    let onAddToCart: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var hasDiscount: Bool {
        product.originalPrice > product.price
    }

    var body: some View {
        HStack(spacing: 12) {
            AppAsyncImage(urlString: product.mainImageURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.secondarySystemBackground)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(width: 80, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(product.category.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if product.isFeaturedActive || product.isNewLaunchActive {
                    HStack(spacing: 6) {
                        if product.isFeaturedActive {
                            badgeLabel("Featured", color: .orange)
                        }
                        if product.isNewLaunchActive {
                            badgeLabel("New", color: .green)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Text("₹\(Int(product.price))")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Color("CleverTapPrimary"))

                    if hasDiscount {
                        Text("₹\(Int(product.originalPrice))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .strikethrough()
                    }
                }
            }

            Spacer()

            Button(action: onAddToCart) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color("CleverTapPrimary"), in: Circle())
            }
        }
        .padding(.vertical, 8)
    }

    private func badgeLabel(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct FiltersSheet: View {
    @Binding var selectedCategory: String
    @Binding var sortOption: ProductListView.SortOption
    @Binding var viewMode: ProductListView.ViewMode
    @Binding var showOnlyDiscounts: Bool
    @Binding var showNewLaunches: Bool
    @Binding var minPrice: Double
    @Binding var maxPrice: Double
    let availableMinPrice: Double
    let availableMaxPrice: Double
    let categories: [String]
    @Environment(\.dismiss) private var dismiss

    private var formattedPriceRange: String {
        let lower = Int(minPrice)
        let upper = Int(maxPrice)
        return "₹\(lower) - ₹\(upper)"
    }

    private var safeMinPrice: Double {
        availableMinPrice
    }

    private var safeMaxPrice: Double {
        max(availableMaxPrice, availableMinPrice + 1)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Layout") {
                    Picker("View", selection: $viewMode) {
                        ForEach(ProductListView.ViewMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Category") {
                    ForEach(categories, id: \.self) { category in
                        HStack {
                            Text(category)
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("CleverTapPrimary"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCategory = category
                        }
                    }
                }

                Section("Sort") {
                    ForEach(ProductListView.SortOption.allCases, id: \.self) { option in
                        HStack {
                            Label(option.rawValue, systemImage: option.systemImage)
                            Spacer()
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("CleverTapPrimary"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sortOption = option
                        }
                    }
                }

                Section("Filters") {
                    Toggle("Only discounts", isOn: $showOnlyDiscounts)
                    Toggle("New launches", isOn: $showNewLaunches)
                }

                Section("Price Range") {
                    Text(formattedPriceRange)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))

                    Slider(value: $minPrice, in: safeMinPrice...safeMaxPrice, step: 50) {
                        Text("Min Price")
                    } minimumValueLabel: {
                        Text("₹\(Int(safeMinPrice))")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("₹\(Int(safeMaxPrice))")
                            .font(.caption)
                    }

                    Slider(value: $maxPrice, in: safeMinPrice...safeMaxPrice, step: 50) {
                        Text("Max Price")
                    } minimumValueLabel: {
                        Text("₹\(Int(safeMinPrice))")
                            .font(.caption)
                    } maximumValueLabel: {
                        Text("₹\(Int(safeMaxPrice))")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: minPrice) { _, newValue in
            if newValue > maxPrice {
                maxPrice = newValue
            }
        }
        .onChange(of: maxPrice) { _, newValue in
            if newValue < minPrice {
                minPrice = newValue
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductListView()
            .environmentObject(CartManager())
    }
}

// MARK: - Shared Shimmer Effect
extension View {
    func shimmering() -> some View {
        self.overlay(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.35),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .rotationEffect(.degrees(15))
            .offset(x: -220)
            .mask(self)
            .animation(
                .linear(duration: 1.2)
                .repeatForever(autoreverses: false),
                value: UUID()
            )
        )
    }
}
