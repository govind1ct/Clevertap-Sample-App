import SwiftUI
import PhotosUI
import UIKit

struct AdminDashboardView: View {
    private enum Workspace: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case products = "Products"
        case banners = "Hero Banners"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .overview:
                return "square.grid.2x2.fill"
            case .products:
                return "shippingbox.fill"
            case .banners:
                return "photo.on.rectangle.angled"
            }
        }
    }

    @StateObject private var productService = ProductService(includeInactiveProducts: true)
    @StateObject private var adminProductService = AdminProductService()
    @StateObject private var orderService = AdminOrderService()
    @StateObject private var heroBannerService = HeroBannerService(includeInactiveBanners: true)
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var showAddSheet = false
    @State private var editProduct: Product?
    @State private var pendingDelete: Product?
    @State private var pendingBulkDeleteProducts: [Product] = []
    @State private var showDeleteConfirmation = false
    @State private var showBulkDeleteConfirmation = false
    @State private var showAdminError = false
    @State private var isSelectionMode = false
    @State private var selectedProductIDs: Set<String> = []
    @State private var selectedWorkspace: Workspace = .overview
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var orderPrefetchTask: Task<Void, Never>?

    private var filteredProducts: [Product] {
        let trimmedSearch = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else { return productService.products }
        return productService.products.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedSearch) ||
            $0.category.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerSection
                    workspaceSwitcher
                    workspaceContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if productService.products.isEmpty {
                productService.fetchProducts()
            }
            if heroBannerService.banners.isEmpty {
                heroBannerService.fetchBanners()
            }
            scheduleOrderPrefetchIfNeeded()
        }
        .onChange(of: adminProductService.errorMessage) { _, newValue in
            showAdminError = newValue != nil
        }
        .onChange(of: searchText) { _, newValue in
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 220_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    debouncedSearchText = newValue
                }
            }
        }
        .onAppear {
            if debouncedSearchText != searchText {
                debouncedSearchText = searchText
            }
        }
        .onDisappear {
            searchDebounceTask?.cancel()
            orderPrefetchTask?.cancel()
        }
        .alert("Admin Action Failed", isPresented: $showAdminError, presenting: adminProductService.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .sheet(isPresented: $showAddSheet) {
            AdminProductEditorView(
                title: "Add Product",
                form: AdminProductFormData(),
                categoryOptions: availableCategoryOptions,
                purposeOptions: purposeOptions,
                chakraOptions: chakraOptions,
                benefitOptions: benefitOptions
            ) { form in
                adminProductService.createProduct(from: form) { result in
                    switch result {
                    case .success:
                        productService.fetchProducts()
                        showAddSheet = false
                    case .failure:
                        break
                    }
                }
            }
        }
        .sheet(item: $editProduct) { product in
            AdminProductEditorView(
                title: "Edit Product",
                form: AdminProductFormData(from: product),
                categoryOptions: availableCategoryOptions,
                purposeOptions: purposeOptions,
                chakraOptions: chakraOptions,
                benefitOptions: benefitOptions
            ) { form in
                guard let productId = product.id else { return }
                adminProductService.updateProduct(productId: productId, data: form) { result in
                    switch result {
                    case .success:
                        productService.fetchProducts()
                        editProduct = nil
                    case .failure:
                        break
                    }
                }
            }
        }
        .alert("Delete Product?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                guard let product = pendingDelete, let productId = product.id else { return }
                adminProductService.deleteProduct(productId: productId, productName: product.name) { result in
                    switch result {
                    case .success:
                        productService.fetchProducts()
                    case .failure:
                        break
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pendingDelete?.name ?? "This product")
        }
        .alert("Delete Selected Products?", isPresented: $showBulkDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                bulkDeleteSelectedProducts()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(pendingBulkDeleteProducts.count) selected products will be permanently removed.")
        }
    }
}

private extension AdminDashboardView {
    var isDarkMode: Bool {
        colorScheme == .dark
    }

    func scheduleOrderPrefetchIfNeeded() {
        guard orderService.orders.isEmpty else { return }
        guard orderPrefetchTask == nil else { return }

        orderPrefetchTask = Task(priority: .utility) {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await orderService.fetchOrders()
            await MainActor.run {
                orderPrefetchTask = nil
            }
        }
    }

    var catalogCount: Int {
        productService.products.count
    }

    var visibleCount: Int {
        filteredProducts.count
    }

    var lowStockCount: Int {
        productService.products.filter(\.isLowStock).count
    }

    var draftCount: Int {
        productService.products.filter { $0.effectiveStatus == "draft" }.count
    }

    var archivedCount: Int {
        productService.products.filter { $0.effectiveStatus == "archived" }.count
    }

    var outOfStockCount: Int {
        productService.products.filter { !$0.isPurchasable }.count
    }

    var orderCount: Int {
        orderService.orders.count
    }

    var processingOrderCount: Int {
        orderService.orders.filter { $0.status.caseInsensitiveCompare("processing") == .orderedSame }.count
    }

    var selectedCount: Int {
        selectedProductIDs.count
    }

    var availableCategoryOptions: [String] {
        let builtInCategories = ProductCategory.allCases.map { $0.rawValue.capitalized }
        let existingCategories = productService.products
            .map(\.category)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.capitalized }

        return Array(Set(builtInCategories + existingCategories)).sorted()
    }

    var purposeOptions: [String] {
        collectUniqueValues(from: productService.products.flatMap(\.purposes))
    }

    var chakraOptions: [String] {
        collectUniqueValues(from: productService.products.flatMap(\.chakras))
    }

    var benefitOptions: [String] {
        collectUniqueValues(from: productService.products.flatMap(\.benefits))
    }

    func collectUniqueValues(from values: [String]) -> [String] {
        Array(
            Set(
                values
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .map { $0.capitalized }
            )
        )
        .sorted()
    }

    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [
                        Color(red: 0.06, green: 0.07, blue: 0.08),
                        Color(red: 0.10, green: 0.10, blue: 0.11),
                        Color(red: 0.14, green: 0.13, blue: 0.12)
                    ]
                    : [
                        Color(red: 0.95, green: 0.94, blue: 0.92),
                        Color(red: 0.92, green: 0.91, blue: 0.88),
                        Color(red: 0.98, green: 0.97, blue: 0.95)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.78, green: 0.58, blue: 0.24).opacity(isDarkMode ? 0.20 : 0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -150, y: -320)

            Circle()
                .fill(Color(red: 0.28, green: 0.44, blue: 0.38).opacity(isDarkMode ? 0.16 : 0.10))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 170, y: -220)

            RoundedRectangle(cornerRadius: 96, style: .continuous)
                .fill(Color.white.opacity(isDarkMode ? 0.03 : 0.18))
                .frame(width: 420, height: 220)
                .blur(radius: 48)
                .rotationEffect(.degrees(-14))
                .offset(x: 110, y: 260)
        }
    }

    var headerSection: some View {
        AdminDashboardHeaderView(
            isDarkMode: isDarkMode,
            isSelectionMode: isSelectionMode,
            productCount: catalogCount,
            orderCount: orderCount,
            processingOrderCount: processingOrderCount,
            visibleCount: visibleCount,
            lowStockCount: lowStockCount,
            selectedCount: selectedCount,
            onAdd: { showAddSheet = true },
            onToggleSelection: { toggleSelectionMode() }
        )
    }

    var workspaceSwitcher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Admin Spaces")
                .font(.caption.weight(.bold))
                .foregroundColor(sectionSecondaryText)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Workspace.allCases) { workspace in
                        Button {
                            withAnimation(.easeInOut(duration: 0.20)) {
                                selectedWorkspace = workspace
                            }
                        } label: {
                            AdminWorkspaceChip(
                                title: workspace.rawValue,
                                systemImage: workspace.systemImage,
                                isSelected: selectedWorkspace == workspace,
                                selectedTextColor: selectedWorkspaceTextColor,
                                secondaryTextColor: sectionSecondaryText,
                                surfaceFill: sectionSurfaceFill,
                                surfaceBorder: sectionSurfaceBorder
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(14)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    var workspaceContent: some View {
        switch selectedWorkspace {
        case .overview:
            overviewWorkspace
        case .products:
            productsWorkspace
        case .banners:
            bannersWorkspace
        }
    }

    var overviewWorkspace: some View {
        VStack(spacing: 18) {
            attentionSection
            operationsPanel
        }
    }

    var productsWorkspace: some View {
        VStack(spacing: 18) {
            if isSelectionMode {
                selectionToolbar
            }
            searchSection

            if productService.isLoading {
                loadingState
            } else if let error = productService.errorMessage {
                errorState(error)
            } else if filteredProducts.isEmpty {
                emptyState
            } else {
                productList
            }
        }
    }

    var bannersWorkspace: some View {
        AdminHeroBannersView()
    }

    var sectionSurfaceFill: Color {
        isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.92)
    }

    var sectionSurfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    var sectionPrimaryText: Color {
        isDarkMode ? Color.white.opacity(0.96) : Color.black.opacity(0.90)
    }

    var sectionSecondaryText: Color {
        isDarkMode ? Color.white.opacity(0.62) : Color.black.opacity(0.56)
    }

    var selectedWorkspaceTextColor: Color {
        isDarkMode ? Color.black.opacity(0.88) : .white
    }

    var selectionToolbar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bulk Edit")
                        .font(.headline.weight(.bold))
                        .foregroundColor(sectionPrimaryText)

                    Text("\(selectedProductIDs.count) products selected")
                        .font(.caption)
                        .foregroundColor(sectionSecondaryText)
                }

                Spacer()

                Button(selectedProductIDs.count == filteredProducts.compactMap(\.id).count ? "Clear Visible" : "Select Visible") {
                    toggleVisibleSelection()
                }
                .font(.caption.weight(.bold))
                .foregroundColor(Color(red: 0.72, green: 0.50, blue: 0.18))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    bulkActionButton(title: "Feature", systemImage: "star.fill", tint: .orange) {
                        bulkUpdateSelectedProducts(fields: ["isFeatured": true], auditAction: "bulk_feature")
                    }
                    bulkActionButton(title: "New Launch", systemImage: "sparkles", tint: .green) {
                        bulkUpdateSelectedProducts(fields: ["isNewLaunch": true], auditAction: "bulk_new_launch")
                    }
                    bulkActionButton(title: "Activate", systemImage: "checkmark.seal.fill", tint: .blue) {
                        bulkUpdateSelectedProducts(fields: ["status": "active"], auditAction: "bulk_activate")
                    }
                    bulkActionButton(title: "Archive", systemImage: "archivebox.fill", tint: .gray) {
                        bulkUpdateSelectedProducts(fields: ["status": "archived"], auditAction: "bulk_archive")
                    }
                    bulkActionButton(title: "Delete", systemImage: "trash.fill", tint: .red) {
                        pendingBulkDeleteProducts = selectedProducts
                        showBulkDeleteConfirmation = true
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.12 : 0.04), radius: 10, y: 6)
    }

    var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Priority Lane")
                .font(.headline.weight(.bold))
                .foregroundColor(sectionPrimaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    attentionCard(
                        title: "Processing",
                        value: "\(processingOrderCount)",
                        subtitle: "Orders",
                        tint: .orange,
                        systemImage: "shippingbox.and.arrow.backward"
                    ) {
                        AdminOrdersView()
                    }

                    attentionCard(
                        title: "Low Stock",
                        value: "\(lowStockCount)",
                        subtitle: "Products",
                        tint: .red,
                        systemImage: "exclamationmark.circle.fill"
                    )

                    attentionCard(
                        title: "Drafts",
                        value: "\(draftCount)",
                        subtitle: "Pending",
                        tint: Color("CleverTapPrimary"),
                        systemImage: "square.and.pencil"
                    )

                    attentionCard(
                        title: "Archived",
                        value: "\(archivedCount)",
                        subtitle: "Hidden",
                        tint: .gray,
                        systemImage: "archivebox.fill"
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(sectionSurfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.14 : 0.04), radius: 10, y: 6)
    }

    var operationsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Launchpad")
                .font(.headline.weight(.bold))
                .foregroundColor(sectionPrimaryText)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                Button {
                    showAddSheet = true
                    selectedWorkspace = .products
                } label: {
                    overviewActionCard(title: "New Product", subtitle: "Create and publish", tint: Color("CleverTapPrimary"), systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AdminOrdersView()
                } label: {
                    overviewActionCard(title: "Orders", subtitle: "Track fulfillment", tint: Color("CleverTapSecondary"), systemImage: "shippingbox.fill")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AdminAuditLogView()
                } label: {
                    overviewActionCard(title: "Audit Trail", subtitle: "See admin activity", tint: .orange, systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.plain)

                Button {
                    selectedWorkspace = .products
                    toggleSelectionMode()
                } label: {
                    overviewActionCard(title: isSelectionMode ? "Exit Bulk" : "Bulk Actions", subtitle: "Manage many products", tint: .green, systemImage: isSelectionMode ? "checkmark.circle.fill" : "checklist")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(sectionSurfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.14 : 0.04), radius: 10, y: 6)
    }

    func overviewActionCard(title: String, subtitle: String, tint: Color, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(isDarkMode ? 0.18 : 0.10))
                    .frame(width: 38, height: 38)

                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(sectionPrimaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(sectionSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(14)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    func attentionCard<Destination: View>(
        title: String,
        value: String,
        subtitle: String,
        tint: Color,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            attentionCardBody(title: title, value: value, subtitle: subtitle, tint: tint, systemImage: systemImage, isInteractive: true)
        }
        .buttonStyle(.plain)
    }

    func attentionCard(
        title: String,
        value: String,
        subtitle: String,
        tint: Color,
        systemImage: String
    ) -> some View {
        attentionCardBody(title: title, value: value, subtitle: subtitle, tint: tint, systemImage: systemImage, isInteractive: false)
    }

    func attentionCardBody(
        title: String,
        value: String,
        subtitle: String,
        tint: Color,
        systemImage: String,
        isInteractive: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tint.opacity(isDarkMode ? 0.18 : 0.12))
                        .frame(width: 30, height: 30)

                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundColor(tint)
                }

                Spacer(minLength: 0)

                if isInteractive {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(sectionSecondaryText)
                }
            }

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(sectionPrimaryText)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(sectionPrimaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(sectionSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(width: 146, alignment: .leading)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    func bulkActionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(selectedProductIDs.isEmpty || adminProductService.isSaving)
        .opacity(selectedProductIDs.isEmpty || adminProductService.isSaving ? 0.5 : 1)
    }

    func dashboardTag(title: String, tint: Color, isNeutral: Bool = false) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundColor(isNeutral ? (isDarkMode ? .white.opacity(0.74) : .secondary) : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                (isNeutral ? Color.black.opacity(isDarkMode ? 0.18 : 0.06) : tint.opacity(0.14)),
                in: Capsule()
            )
    }

    var searchSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Catalog Console")
                        .font(.headline.weight(.bold))
                        .foregroundColor(sectionPrimaryText)

                    Text("Search, filter mentally, and act fast.")
                        .font(.caption)
                        .foregroundColor(sectionSecondaryText)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(sectionSecondaryText)

                TextField("Search products, categories, stock state", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(isDarkMode ? .white : .primary)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(sectionSecondaryText)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    dashboardTag(title: isSelectionMode ? "Bulk mode" : "Single edit", tint: isSelectionMode ? .orange : Color(red: 0.72, green: 0.50, blue: 0.18))
                    dashboardTag(title: productService.isLoading ? "Syncing" : "Live catalog", tint: productService.isLoading ? .blue : .green)
                    dashboardTag(title: "\(filteredProducts.count) results", tint: .secondary, isNeutral: true)
                    dashboardTag(title: "\(outOfStockCount) unavailable", tint: .red)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(sectionSurfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    var productList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Products")
                        .font(.headline.weight(.bold))
                        .foregroundColor(sectionPrimaryText)
                    Text("Edit and manage the live catalog.")
                        .font(.caption)
                        .foregroundColor(sectionSecondaryText)
                }

                Spacer()

                Text("\(filteredProducts.count) items")
                    .font(.caption.weight(.bold))
                    .foregroundColor(isDarkMode ? .white.opacity(0.72) : Color("CleverTapPrimary"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04), in: Capsule())
            }

            LazyVStack(spacing: 14) {
                ForEach(filteredProducts) { product in
                    AdminProductCard(product: product, isSelectionMode: isSelectionMode) {
                        editProduct = product
                    } onToggleFeatured: {
                        toggleFeatured(for: product)
                    } onToggleNewLaunch: {
                        toggleNewLaunch(for: product)
                    } onCycleStatus: {
                        cycleStatus(for: product)
                    } onDelete: {
                        pendingDelete = product
                        showDeleteConfirmation = true
                    } onToggleSelection: {
                        toggleSelection(for: product)
                    }
                    .overlay(alignment: .topLeading) {
                        if isSelectionMode {
                            selectionIndicator(for: product)
                                .padding(12)
                        }
                    }
                }
            }
        }
        .padding(.top, 2)
        .refreshable {
            productService.fetchProducts()
            try? await Task.sleep(nanoseconds: 600_000_000)
        }
    }

    func selectionIndicator(for product: Product) -> some View {
        let selected = isSelected(product)
        return Image(systemName: selected ? "checkmark.circle.fill" : "circle")
            .font(.title3.weight(.semibold))
            .foregroundColor(selected ? Color("CleverTapPrimary") : .secondary)
            .padding(6)
            .background(.ultraThinMaterial, in: Circle())
    }

    var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color(red: 0.72, green: 0.50, blue: 0.18))
            Text("Loading catalog")
                .font(.headline.weight(.bold))
                .foregroundColor(sectionPrimaryText)
            Text("Fetching the latest products for admin review.")
                .font(.caption)
                .foregroundColor(sectionSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38))
                .foregroundColor(.orange)
            Text("Catalog unavailable")
                .font(.headline.weight(.bold))
                .foregroundColor(sectionPrimaryText)
            Text(message)
                .font(.subheadline)
                .foregroundColor(sectionSecondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                productService.fetchProducts()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundColor(sectionSecondaryText)
            Text("No products yet")
                .font(.headline.weight(.bold))
                .foregroundColor(sectionPrimaryText)
            Text("Add the first product to start managing the catalog.")
                .font(.subheadline)
                .foregroundColor(sectionSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    func toggleFeatured(for product: Product) {
        guard let productId = product.id else { return }
        adminProductService.updateProductFields(
            productId: productId,
            productName: product.name,
            fields: ["isFeatured": !product.isFeatured],
            auditAction: "quick_toggle_featured"
        ) { result in
            if case .success = result {
                productService.fetchProducts()
            }
        }
    }

    func toggleNewLaunch(for product: Product) {
        guard let productId = product.id else { return }
        adminProductService.updateProductFields(
            productId: productId,
            productName: product.name,
            fields: ["isNewLaunch": !product.isNewLaunch],
            auditAction: "quick_toggle_new_launch"
        ) { result in
            if case .success = result {
                productService.fetchProducts()
            }
        }
    }

    func cycleStatus(for product: Product) {
        guard let productId = product.id else { return }
        let nextStatus: String

        switch product.effectiveStatus {
        case "draft":
            nextStatus = "active"
        case "active":
            nextStatus = "archived"
        default:
            nextStatus = "draft"
        }

        adminProductService.updateProductFields(
            productId: productId,
            productName: product.name,
            fields: ["status": nextStatus],
            auditAction: "quick_cycle_status"
        ) { result in
            if case .success = result {
                productService.fetchProducts()
            }
        }
    }

    var selectedProducts: [Product] {
        productService.products.filter { product in
            guard let productId = product.id else { return false }
            return selectedProductIDs.contains(productId)
        }
    }

    func isSelected(_ product: Product) -> Bool {
        guard let productId = product.id else { return false }
        return selectedProductIDs.contains(productId)
    }

    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedProductIDs.removeAll()
        }
    }

    func toggleSelection(for product: Product) {
        guard let productId = product.id else { return }
        if isSelected(product) {
            selectedProductIDs.remove(productId)
        } else {
            selectedProductIDs.insert(productId)
        }
    }

    func toggleVisibleSelection() {
        let visibleIDs = Set(filteredProducts.compactMap(\.id))
        let allVisibleSelected = !visibleIDs.isEmpty && visibleIDs.isSubset(of: selectedProductIDs)

        if allVisibleSelected {
            selectedProductIDs.subtract(visibleIDs)
        } else {
            selectedProductIDs.formUnion(visibleIDs)
        }
    }

    func bulkUpdateSelectedProducts(fields: [String: Any], auditAction: String) {
        let productIDs = Array(selectedProductIDs)
        adminProductService.bulkUpdateProducts(productIDs: productIDs, fields: fields, auditAction: auditAction) { result in
            if case .success = result {
                selectedProductIDs.removeAll()
                isSelectionMode = false
                productService.fetchProducts()
            }
        }
    }

    func bulkDeleteSelectedProducts() {
        let productsToDelete = pendingBulkDeleteProducts.compactMap { product -> (id: String, name: String)? in
            guard let productId = product.id else { return nil }
            return (id: productId, name: product.name)
        }

        adminProductService.bulkDeleteProducts(products: productsToDelete) { result in
            if case .success = result {
                selectedProductIDs.removeAll()
                pendingBulkDeleteProducts = []
                isSelectionMode = false
                productService.fetchProducts()
            }
        }
    }
}

private struct StatBadge: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary.opacity(0.8))
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            Text(caption)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(width: 120, alignment: .leading)
        .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct AdminProductCard: View {
    let product: Product
    let isSelectionMode: Bool
    let onEdit: () -> Void
    let onToggleFeatured: () -> Void
    let onToggleNewLaunch: () -> Void
    let onCycleStatus: () -> Void
    let onDelete: () -> Void
    let onToggleSelection: () -> Void
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

    private var accent: Color {
        Color(red: 0.72, green: 0.50, blue: 0.18)
    }

    private var stockColor: Color {
        switch product.effectiveStatus {
        case "draft":
            return .orange
        case "archived":
            return .gray
        default:
            if product.resolvedStockQuantity == 0 { return .red }
            if product.isLowStock { return .orange }
            return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                productImage

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.name)
                                .font(.headline.weight(.bold))
                                .foregroundColor(primaryText)
                                .lineLimit(2)

                            Text(product.category.capitalized)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(secondaryText)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        statusPill(title: product.stockLabel, tint: stockColor)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            merchandisingBadges
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            merchandisingBadges
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("₹\(Int(product.price))")
                            .font(.title3.weight(.black))
                            .foregroundColor(accent)

                        if hasDiscount {
                            Text("₹\(Int(product.originalPrice))")
                                .font(.caption)
                                .foregroundColor(secondaryText)
                                .strikethrough()
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                summaryMetric(title: "Status", value: product.effectiveStatus.capitalized, tint: stockColor)
                summaryMetric(title: "Stock", value: "\(product.resolvedStockQuantity)", tint: stockColor)
                if !isSelectionMode {
                    summaryMetric(title: "Keywords", value: "\(product.searchKeywords.count)", tint: accent)
                }
            }

            if !isSelectionMode {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        quickActionButton(label: "Edit", systemName: "square.and.pencil", tint: accent, action: onEdit)
                        quickActionButton(label: product.isFeatured ? "Featured" : "Feature", systemName: product.isFeatured ? "star.fill" : "star", tint: .orange, action: onToggleFeatured)
                        quickActionButton(label: product.isNewLaunch ? "Launch" : "Mark Launch", systemName: "sparkles", tint: .green, action: onToggleNewLaunch)
                        quickActionButton(label: "Status", systemName: "arrow.triangle.2.circlepath", tint: stockColor, action: onCycleStatus)
                        quickActionButton(label: "Delete", systemName: "trash", tint: .red, action: onDelete)
                    }
                }
            }
        }
        .padding(16)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.16 : 0.05), radius: 12, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            }
        }
    }

    private var primaryText: Color {
        isDarkMode ? Color.white.opacity(0.96) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.62) : Color.black.opacity(0.56)
    }

    private var cardFill: Color {
        isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.94)
    }

    var productImage: some View {
        AppAsyncImage(urlString: product.mainImageURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [accent.opacity(0.34), Color(red: 0.31, green: 0.46, blue: 0.40).opacity(0.24)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.92))
                )
            }
        }
        .frame(width: 92, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var cardBorder: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    func quickActionButton(label: String, systemName: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: systemName)
                    .font(.caption.weight(.bold))

                Text(label)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
            }
            .foregroundColor(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(tint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var merchandisingBadges: some View {
        if product.isNewLaunch {
            statusPill(title: "NEW", tint: .green)
        }

        if product.isFeatured {
            statusPill(title: "FEATURED", tint: .orange)
        }

        if hasDiscount {
            discountPill
        }
    }

    func summaryMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(secondaryText)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(tint == accent ? primaryText : tint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func statusPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }

    var discountPill: some View {
        Text("\(discountPercent)% OFF")
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.red, in: Capsule())
    }
}

private struct AdminWorkspaceChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let selectedTextColor: Color
    let secondaryTextColor: Color
    let surfaceFill: Color
    let surfaceBorder: Color

    private var accent: Color {
        Color(red: 0.72, green: 0.50, blue: 0.18)
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.16) : accent.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundColor(isSelected ? selectedTextColor : accent)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
            }
        }
        .foregroundColor(isSelected ? selectedTextColor : secondaryTextColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.clear : surfaceBorder, lineWidth: 1)
        )
    }

    private var backgroundStyle: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(accent)
        } else {
            return AnyShapeStyle(surfaceFill)
        }
    }
}


struct AdminProductEditorView: View {
    private enum EditorStep: String, CaseIterable, Identifiable {
        case basics = "Basics"
        case media = "Media"
        case commerce = "Commerce"
        case launch = "Launch"

        var id: String { rawValue }

        var subtitle: String {
            switch self {
            case .basics:
                return "Identity and copy"
            case .media:
                return "Images and gallery"
            case .commerce:
                return "Price, stock, and details"
            case .launch:
                return "Merchandising and visibility"
            }
        }
    }

    let title: String
    @State var form: AdminProductFormData
    let categoryOptions: [String]
    let purposeOptions: [String]
    let chakraOptions: [String]
    let benefitOptions: [String]
    let onSave: (AdminProductFormData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var imageUploadService = AdminProductImageUploadService()
    @State private var showValidationAlert = false
    @State private var validationAlertMessage = "Name, category, and description are required."
    @State private var selectedPrimaryImageItem: PhotosPickerItem?
    @State private var selectedGalleryImageItems: [PhotosPickerItem] = []
    @State private var mediaAlertMessage = ""
    @State private var showMediaAlert = false
    @State private var selectedStep: EditorStep = .basics
    @State private var customCategoryOptions: [String] = []

    private enum DraftStorage {
        static let formKey = "admin_product_editor_draft_form_v1"
        static let stepKey = "admin_product_editor_draft_step_v1"
        static let categoriesKey = "admin_product_editor_draft_categories_v1"
    }

    private var isAddMode: Bool {
        title.localizedCaseInsensitiveContains("add")
    }

    private var isValid: Bool {
        !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var mergedCategoryOptions: [String] {
        Array(Set(categoryOptions + customCategoryOptions))
            .sorted()
    }

    private var galleryImageURLs: [String] {
        form.imagesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var previewImageURL: String {
        let primary = form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !primary.isEmpty {
            return primary
        }

        return galleryImageURLs.first ?? ""
    }

    private var validationMessages: [EditorValidationMessage] {
        var messages: [EditorValidationMessage] = []

        if form.price <= 0 {
            messages.append(EditorValidationMessage(text: "Price should be greater than 0.", kind: .error))
        }

        if form.originalPrice > 0, form.originalPrice < form.price {
            messages.append(EditorValidationMessage(text: "Original price is lower than the selling price.", kind: .warning))
        }

        if previewImageURL.isEmpty {
            messages.append(EditorValidationMessage(text: "Add a primary image or at least one gallery image.", kind: .warning))
        }

        if form.status == "active", form.stockQuantity == 0 {
            messages.append(EditorValidationMessage(text: "Active products with zero stock will appear out of stock.", kind: .warning))
        }

        if form.searchKeywordsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(EditorValidationMessage(text: "Search keywords are empty, which hurts discoverability.", kind: .warning))
        }

        if form.homePlacementSlot < 0 {
            messages.append(EditorValidationMessage(text: "Home placement slot should be 0 or greater.", kind: .error))
        }

        if form.categorySortPriority < 0 {
            messages.append(EditorValidationMessage(text: "Category sort priority should be 0 or greater.", kind: .error))
        }

        if form.hasFeaturedSchedule, form.featuredEndAt < form.featuredStartAt {
            messages.append(EditorValidationMessage(text: "Featured schedule ends before it starts.", kind: .error))
        }

        if form.hasNewLaunchSchedule, form.newLaunchEndAt < form.newLaunchStartAt {
            messages.append(EditorValidationMessage(text: "New launch schedule ends before it starts.", kind: .error))
        }

        return messages
    }

    private var requiredFieldCompletionCount: Int {
        var count = 0
        if !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if !form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if form.price > 0 { count += 1 }
        return count
    }

    private var saveButtonTitle: String {
        isAddMode ? "Create Product" : "Save Changes"
    }

    private var isBasicsStepValid: Bool {
        !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentStepIndex: Int {
        EditorStep.allCases.firstIndex(of: selectedStep) ?? 0
    }

    private var isLastStep: Bool {
        currentStepIndex == EditorStep.allCases.count - 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: isDarkMode
                        ? [
                            Color(.systemBackground),
                            Color(red: 0.08, green: 0.10, blue: 0.14),
                            Color(.systemGroupedBackground)
                        ]
                        : [
                            Color("CleverTapPrimary").opacity(0.16),
                            Color("CleverTapSecondary").opacity(0.10),
                            Color(.systemBackground),
                            Color(.systemBackground)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.12))
                    .frame(width: 240, height: 240)
                    .blur(radius: 34)
                    .offset(x: -150, y: -300)

                Circle()
                    .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.10))
                    .frame(width: 280, height: 280)
                    .blur(radius: 42)
                    .offset(x: 170, y: -240)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        stepFlowHeader
                        stepStrip
                        currentStepContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .safeAreaInset(edge: .bottom) {
                stepFooter
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(.ultraThinMaterial)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if isAddMode {
                    restoreDraftIfAvailable()
                }
            }
            .onChange(of: form) { _, _ in
                persistDraftIfNeeded()
            }
            .onChange(of: selectedStep) { _, _ in
                persistDraftIfNeeded()
            }
            .onChange(of: customCategoryOptions) { _, _ in
                persistDraftIfNeeded()
            }
            .onChange(of: selectedPrimaryImageItem?.itemIdentifier) { _, _ in
                Task {
                    await handlePrimaryImageSelection()
                }
            }
            .onChange(of: selectedGalleryImageItems.count) { _, _ in
                Task {
                    await handleGalleryImageSelection()
                }
            }
            .alert("Missing required fields", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationAlertMessage)
            }
            .alert("Media Upload", isPresented: $showMediaAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(mediaAlertMessage)
            }
        }
    }
}

private extension AdminProductEditorView {
    func persistDraftIfNeeded() {
        guard isAddMode else { return }
        let defaults = UserDefaults.standard

        if let data = try? JSONEncoder().encode(form) {
            defaults.set(data, forKey: DraftStorage.formKey)
        }

        defaults.set(selectedStep.rawValue, forKey: DraftStorage.stepKey)
        defaults.set(customCategoryOptions, forKey: DraftStorage.categoriesKey)
    }

    func restoreDraftIfAvailable() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: DraftStorage.formKey),
           let draft = try? JSONDecoder().decode(AdminProductFormData.self, from: data) {
            form = draft
        }

        if let rawStep = defaults.string(forKey: DraftStorage.stepKey),
           let draftStep = EditorStep(rawValue: rawStep) {
            selectedStep = draftStep
        }

        customCategoryOptions = defaults.stringArray(forKey: DraftStorage.categoriesKey) ?? []
    }

    func clearDraftIfNeeded() {
        guard isAddMode else { return }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: DraftStorage.formKey)
        defaults.removeObject(forKey: DraftStorage.stepKey)
        defaults.removeObject(forKey: DraftStorage.categoriesKey)
    }

    func addCategoryFromEditor(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !mergedCategoryOptions.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            customCategoryOptions.append(trimmed.capitalized)
        }
        form.category = trimmed.capitalized
    }

    private func attemptStepSelection(_ step: EditorStep) {
        if step != .basics && !isBasicsStepValid {
            validationAlertMessage = "Complete Basics first: name, category, and description are required before moving ahead."
            showValidationAlert = true
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            selectedStep = step
        }
    }

    private func goToNextStep() {
        guard !isLastStep else {
            submitForm()
            return
        }

        if selectedStep == .basics && !isBasicsStepValid {
            validationAlertMessage = "Complete Basics first: name, category, and description are required before moving ahead."
            showValidationAlert = true
            return
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            selectedStep = EditorStep.allCases[min(currentStepIndex + 1, EditorStep.allCases.count - 1)]
        }
    }

    @ViewBuilder
    var currentStepContent: some View {
        switch selectedStep {
        case .basics:
            previewSection
            basicsSection
        case .media:
            mediaSection
        case .commerce:
            pricingSection
            tagsSection
            detailsSection
        case .launch:
            validationSection
            merchandisingSection
            flagsSection
            finalReviewSection
        }
    }

    func submitForm() {
        if isValid {
            clearDraftIfNeeded()
            onSave(form)
        } else {
            validationAlertMessage = "Name, category, and description are required."
            showValidationAlert = true
        }
    }

    var stepFlowHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                editorChip(title: isAddMode ? "QUICK ADD" : "EDITOR", tint: Color("CleverTapPrimary"))
                editorChip(title: "STEP \(currentStepIndex + 1) / \(EditorStep.allCases.count)", tint: Color("CleverTapSecondary"))
            }

            Text(isAddMode ? "Add Product" : "Edit Product")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(selectedStep.subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(selectedStep.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentStepIndex + 1) of \(EditorStep.allCases.count)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("CleverTapPrimary"))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * CGFloat(currentStepIndex + 1) / CGFloat(EditorStep.allCases.count))
                    }
                }
                .frame(height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var stepStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EditorStep.allCases) { step in
                    Button {
                        attemptStepSelection(step)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.rawValue)
                                .font(.caption.weight(.bold))
                            Text(step.subtitle)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .foregroundColor(selectedStep == step ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(width: 118, alignment: .leading)
                        .background(
                            selectedStep == step
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(.thinMaterial),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var stepFooter: some View {
        HStack(spacing: 10) {
            if currentStepIndex > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                        selectedStep = EditorStep.allCases[max(currentStepIndex - 1, 0)]
                    }
                }
                .buttonStyle(AdminEditorGhostButtonStyle())
            }

            Spacer(minLength: 0)

            if isLastStep {
                Button(imageUploadService.isUploading ? "Uploading..." : saveButtonTitle) {
                    submitForm()
                }
                .buttonStyle(AdminEditorPrimaryButtonStyle())
                .disabled(imageUploadService.isUploading)
            } else {
                Button("Next") {
                    goToNextStep()
                }
                .buttonStyle(AdminEditorPrimaryButtonStyle())
            }
        }
    }

    var finalReviewSection: some View {
        AdminEditorSection(title: "Review", subtitle: "Final confirmation before saving the product.") {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    mediaSummaryCard(title: "Required", value: "\(requiredFieldCompletionCount)/4")
                    mediaSummaryCard(title: "Warnings", value: "\(validationMessages.count)")
                }

                HStack(spacing: 12) {
                    mediaSummaryCard(title: "Status", value: form.status.capitalized)
                    mediaSummaryCard(title: "Media", value: "\(galleryImageURLs.count + (previewImageURL.isEmpty ? 0 : 1))")
                }
            }
        }
    }

    func editorChip(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }

    func mediaSummaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var basicsSection: some View {
        AdminEditorSection(title: "Essentials", subtitle: "Core product identity and storefront copy.") {
            VStack(spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AdminEditorTextField(title: "Product Name", text: $form.name)
                    AdminCategoryField(
                        text: $form.category,
                        options: mergedCategoryOptions,
                        onAddCategory: addCategoryFromEditor
                    )
                }

                AdminEditorTextField(title: "Short Description", text: $form.shortDescription)
                AdminEditorTextField(title: "Description", text: $form.description, axis: .vertical, lineLimit: 5...8)
            }
        }
    }

    var previewSection: some View {
        AdminEditorSection(title: "Storefront Preview", subtitle: "Live card preview while you fill the form.") {
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    AdminEditorImagePreview(urlString: previewImageURL)
                        .frame(width: 116, height: 140)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Product" : form.name)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                            .lineLimit(3)

                        Text(form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No category selected" : form.category.capitalized)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("₹\(Int(form.price))")
                                .font(.headline.weight(.bold))
                                .foregroundColor(Color("CleverTapPrimary"))

                            if form.originalPrice > form.price, form.originalPrice > 0 {
                                Text("₹\(Int(form.originalPrice))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                            }
                        }

                        Text(form.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Add a short description to improve product cards." : form.shortDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        editorPill(title: stockPreviewLabel, tint: stockPreviewColor)

                        if isFeaturedPreviewActive {
                            editorPill(title: "Featured", tint: .orange)
                        }

                        if isNewLaunchPreviewActive {
                            editorPill(title: "New Launch", tint: .green)
                        }

                        if form.isCategoryPinned {
                            editorPill(title: "Pinned", tint: .blue)
                        }

                        editorPill(title: form.status.capitalized, tint: form.status == "active" ? Color("CleverTapPrimary") : .gray)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var validationSection: some View {
        if !validationMessages.isEmpty {
            AdminEditorSection(title: "Checks", subtitle: "Potential storefront issues detected from the current form.") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(validationMessages) { message in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: message.kind.icon)
                                .foregroundColor(message.kind.color)
                                .frame(width: 18)

                            Text(message.text)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(message.kind.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }

    var pricingSection: some View {
        AdminEditorSection(title: "Commerce", subtitle: "Price, stock, publishing state, and energy profile.") {
            VStack(spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AdminEditorNumberField(title: "Price", value: $form.price)
                    AdminEditorNumberField(title: "Original Price", value: $form.originalPrice)
                    AdminEditorIntegerField(title: "Stock Quantity", value: $form.stockQuantity)
                    AdminEditorIntegerField(title: "Low Stock Alert", value: $form.lowStockThreshold)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Status")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        editorPill(title: form.status.capitalized, tint: form.status == "active" ? Color("CleverTapPrimary") : .gray)
                    }

                    Picker("Status", selection: $form.status) {
                        Text("Draft").tag("draft")
                        Text("Active").tag("active")
                        Text("Archived").tag("archived")
                    }
                    .pickerStyle(.segmented)
                }
                .adminFieldSurface()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Energy Level")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        editorPill(title: "\(form.energyLevel)/10", tint: Color("CleverTapPrimary"))
                    }

                    Stepper("Energy", value: $form.energyLevel, in: 0...10)
                        .labelsHidden()
                }
                .adminFieldSurface()
            }
        }
    }

    var merchandisingSection: some View {
        AdminEditorSection(title: "Merchandising", subtitle: "Ranking, home placement, and timed visibility controls.") {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AdminEditorIntegerField(title: "Merchandising Priority", value: $form.merchandisingPriority)
                    AdminEditorIntegerField(title: "Home Placement Slot", value: $form.homePlacementSlot)
                    AdminEditorIntegerField(title: "Category Sort Priority", value: $form.categorySortPriority)
                }

                Toggle(isOn: $form.isCategoryPinned) {
                    AdminToggleLabel(title: "Pin In Category", subtitle: "Keep this product at the top of its category listing.")
                }
                .adminToggleSurface()

                AdminEditorTextField(
                    title: "Campaign Tags",
                    text: $form.campaignTagsText,
                    axis: .vertical,
                    lineLimit: 2...4
                )

                scheduleCard(
                    title: "Featured Schedule",
                    subtitle: "Restrict featured placements to a specific time window.",
                    isEnabled: $form.hasFeaturedSchedule,
                    startDate: $form.featuredStartAt,
                    endDate: $form.featuredEndAt
                )

                scheduleCard(
                    title: "New Launch Schedule",
                    subtitle: "Keep the new-launch badge active only during launch windows.",
                    isEnabled: $form.hasNewLaunchSchedule,
                    startDate: $form.newLaunchStartAt,
                    endDate: $form.newLaunchEndAt
                )
            }
        }
    }

    var tagsSection: some View {
        AdminEditorSection(title: "Discovery", subtitle: "Search and recommendation metadata used across the catalog.") {
            VStack(spacing: 12) {
                AdminSmartListField(title: "Purposes", text: $form.purposesText, options: purposeOptions)
                AdminSmartListField(title: "Chakras", text: $form.chakrasText, options: chakraOptions)
                AdminSmartListField(title: "Benefits", text: $form.benefitsText, options: benefitOptions)
                AdminEditorTextField(title: "Search Keywords", text: $form.searchKeywordsText)
            }
        }
    }

    var mediaSection: some View {
        AdminEditorSection(title: "Media Studio", subtitle: "Upload, arrange, and promote product imagery.") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    PhotosPicker(selection: $selectedPrimaryImageItem, matching: .images) {
                        AdminMediaButton(
                            title: "Upload Primary",
                            systemImage: "photo.badge.plus",
                            tint: Color("CleverTapPrimary")
                        )
                    }

                    PhotosPicker(selection: $selectedGalleryImageItems, maxSelectionCount: 6, matching: .images) {
                        AdminMediaButton(
                            title: "Add Gallery",
                            systemImage: "square.stack.3d.up",
                            tint: Color("CleverTapSecondary")
                        )
                    }
                }
                .disabled(imageUploadService.isUploading)
                .opacity(imageUploadService.isUploading ? 0.65 : 1)

                HStack(spacing: 12) {
                    mediaSummaryCard(title: "Primary", value: form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not set" : "Ready")
                    mediaSummaryCard(title: "Gallery", value: "\(galleryImageURLs.count) items")
                }

                if imageUploadService.isUploading {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Uploading selected image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !galleryImageURLs.isEmpty {
                    galleryManagerSection
                }

                AdminEditorTextField(title: "Images", text: $form.imagesText, axis: .vertical, lineLimit: 3...5)
                AdminEditorTextField(title: "Primary Image URL", text: $form.imageURL, axis: .vertical, lineLimit: 2...4)
            }
        }
    }

    var galleryManagerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Gallery")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(galleryImageURLs.enumerated()), id: \.offset) { index, url in
                        AdminGalleryImageCard(
                            urlString: url,
                            isPrimaryFallback: form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && index == 0,
                            canMoveLeft: index > 0,
                            canMoveRight: index < galleryImageURLs.count - 1,
                            onMoveLeft: { moveGalleryImage(from: index, direction: -1) },
                            onMoveRight: { moveGalleryImage(from: index, direction: 1) },
                            onSetPrimary: { setPrimaryImage(from: index) },
                            onRemove: { removeGalleryImage(at: index) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }

            Text("Reorder gallery images, remove unwanted uploads, or promote a gallery image to the primary slot.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var detailsSection: some View {
        AdminEditorSection(title: "Product Details", subtitle: "Long-form information used in product detail screens.") {
            VStack(spacing: 12) {
                AdminEditorTextField(
                    title: "Availability Message",
                    text: $form.availabilityMessage,
                    axis: .vertical,
                    lineLimit: 2...4
                )
                AdminEditorTextField(title: "Care Instructions", text: $form.careInstructions, axis: .vertical, lineLimit: 3...5)
                AdminEditorTextField(title: "Specifications", text: $form.specificationsText, axis: .vertical, lineLimit: 3...5)
            }
        }
    }

    var flagsSection: some View {
        AdminEditorSection(title: "Visibility", subtitle: "Storefront badges and promotional switches.") {
            VStack(spacing: 12) {
                Toggle(isOn: $form.isNewLaunch) {
                    AdminToggleLabel(title: "New Launch", subtitle: "Highlights the product as recently launched.")
                }
                .adminToggleSurface()

                Toggle(isOn: $form.isFeatured) {
                    AdminToggleLabel(title: "Featured", subtitle: "Promotes the product in featured placements.")
                }
                .adminToggleSurface()
            }
        }
    }

    private func handlePrimaryImageSelection() async {
        guard let selectedPrimaryImageItem else { return }
        defer { self.selectedPrimaryImageItem = nil }

        do {
            guard let data = try await selectedPrimaryImageItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw AdminProductImageUploadError.processingFailed
            }

            let uploadedURL = try await imageUploadService.uploadProductImage(image, kind: "primary")
            await MainActor.run {
                form.imageURL = uploadedURL
            }
        } catch {
            await MainActor.run {
                mediaAlertMessage = error.localizedDescription
                showMediaAlert = true
            }
        }
    }

    private func handleGalleryImageSelection() async {
        guard !selectedGalleryImageItems.isEmpty else { return }
        let selectedItems = selectedGalleryImageItems
        defer { self.selectedGalleryImageItems = [] }

        do {
            var uploadedURLs: [String] = []
            for item in selectedItems {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw AdminProductImageUploadError.processingFailed
                }
                let uploadedURL = try await imageUploadService.uploadProductImage(image, kind: "gallery")
                uploadedURLs.append(uploadedURL)
            }

            await MainActor.run {
                let existingURLs = galleryImageURLs
                let updatedGalleryURLs = existingURLs + uploadedURLs
                form.imagesText = updatedGalleryURLs.joined(separator: ", ")
                if form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let firstUploadedURL = uploadedURLs.first {
                    form.imageURL = firstUploadedURL
                }
            }
        } catch {
            await MainActor.run {
                mediaAlertMessage = error.localizedDescription
                showMediaAlert = true
            }
        }
    }

    private func moveGalleryImage(from index: Int, direction: Int) {
        var urls = galleryImageURLs
        let targetIndex = index + direction
        guard urls.indices.contains(index), urls.indices.contains(targetIndex) else { return }
        urls.swapAt(index, targetIndex)
        form.imagesText = urls.joined(separator: ", ")
    }

    private func removeGalleryImage(at index: Int) {
        var urls = galleryImageURLs
        guard urls.indices.contains(index) else { return }
        let removedURL = urls.remove(at: index)
        form.imagesText = urls.joined(separator: ", ")

        if form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines) == removedURL {
            form.imageURL = urls.first ?? ""
        }
    }

    private func setPrimaryImage(from index: Int) {
        guard galleryImageURLs.indices.contains(index) else { return }
        form.imageURL = galleryImageURLs[index]
    }

    var stockPreviewLabel: String {
        if form.status == "draft" { return "Draft" }
        if form.status == "archived" { return "Archived" }
        if form.stockQuantity <= 0 { return "Out of Stock" }
        if form.stockQuantity <= max(form.lowStockThreshold, 1) { return "Low Stock" }
        return "In Stock"
    }

    var stockPreviewColor: Color {
        if form.status == "draft" { return .orange }
        if form.status == "archived" { return .gray }
        if form.stockQuantity <= 0 { return .red }
        if form.stockQuantity <= max(form.lowStockThreshold, 1) { return .orange }
        return .green
    }

    var isFeaturedPreviewActive: Bool {
        form.isFeatured && isScheduleActive(
            isEnabled: form.hasFeaturedSchedule,
            startDate: form.featuredStartAt,
            endDate: form.featuredEndAt
        )
    }

    var isNewLaunchPreviewActive: Bool {
        form.isNewLaunch && isScheduleActive(
            isEnabled: form.hasNewLaunchSchedule,
            startDate: form.newLaunchStartAt,
            endDate: form.newLaunchEndAt
        )
    }

    @ViewBuilder
    func scheduleCard(
        title: String,
        subtitle: String,
        isEnabled: Binding<Bool>,
        startDate: Binding<Date>,
        endDate: Binding<Date>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: isEnabled) {
                AdminToggleLabel(title: title, subtitle: subtitle)
            }

            if isEnabled.wrappedValue {
                VStack(spacing: 10) {
                    DatePicker("Starts", selection: startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Ends", selection: endDate, displayedComponents: [.date, .hourAndMinute])
                }
                .datePickerStyle(.compact)
                .font(.subheadline)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func isScheduleActive(isEnabled: Bool, startDate: Date, endDate: Date) -> Bool {
        guard isEnabled else { return true }
        let now = Date()
        return startDate <= now && endDate >= now
    }

    func editorPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

private struct AdminEditorSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color("CleverTapPrimary"))
                    .tracking(0.8)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

private extension View {
    func adminFieldSurface() -> some View {
        self
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
    }

    func adminToggleSurface() -> some View {
        self
            .padding(14)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
    }
}

private struct AdminEditorTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int> = 1...1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            TextField(title, text: $text, axis: axis)
                .lineLimit(lineLimit)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        }
    }
}

private struct AdminCategoryField: View {
    @Binding var text: String
    let options: [String]
    var onAddCategory: ((String) -> Void)? = nil

    private var filteredOptions: [String] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return options }

        return options.filter { option in
            option.localizedCaseInsensitiveContains(trimmedText)
        }
    }

    private var canAddTypedCategory: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return false }
        return !options.contains { $0.caseInsensitiveCompare(trimmedText) == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            TextField("Category", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )

            if !filteredOptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filteredOptions, id: \.self) { option in
                            Button(option) {
                                text = option
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(text.caseInsensitiveCompare(option) == .orderedSame ? .white : Color("CleverTapPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                text.caseInsensitiveCompare(option) == .orderedSame
                                    ? Color("CleverTapPrimary")
                                    : Color("CleverTapPrimary").opacity(0.12),
                                in: Capsule()
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if canAddTypedCategory {
                Button {
                    onAddCategory?(text)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add \"\(text.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("CleverTapPrimary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color("CleverTapPrimary").opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("Choose from existing categories or type a new one.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct AdminSmartListField: View {
    let title: String
    @Binding var text: String
    let options: [String]

    private var selectedValues: [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var availableOptions: [String] {
        options.filter { option in
            !selectedValues.contains { $0.caseInsensitiveCompare(option) == .orderedSame }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdminEditorTextField(title: title, text: $text)

            if !availableOptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableOptions, id: \.self) { option in
                            Button(option) {
                                append(option)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("CleverTapPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func append(_ option: String) {
        if selectedValues.isEmpty {
            text = option
        } else {
            text += ", \(option)"
        }
    }
}

private struct AdminEditorNumberField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            TextField(title, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        }
    }
}

private struct AdminEditorIntegerField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            TextField(title, value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
        }
    }
}

private struct AdminToggleLabel: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AdminGalleryImageCard: View {
    let urlString: String
    let isPrimaryFallback: Bool
    let canMoveLeft: Bool
    let canMoveRight: Bool
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onSetPrimary: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                AdminEditorImagePreview(urlString: urlString)
                    .frame(width: 110, height: 126)

                if isPrimaryFallback {
                    Text("Preview")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color("CleverTapPrimary"), in: Capsule())
                        .padding(8)
                }
            }

            HStack(spacing: 8) {
                Button(action: onMoveLeft) {
                    Image(systemName: "arrow.left")
                }
                .disabled(!canMoveLeft)

                Button(action: onMoveRight) {
                    Image(systemName: "arrow.right")
                }
                .disabled(!canMoveRight)

                Spacer(minLength: 0)

                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)

            Button(action: onSetPrimary) {
                Text("Set Primary")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("CleverTapPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color("CleverTapPrimary").opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 138)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AdminMediaButton: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundColor(tint)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AdminEditorImagePreview: View {
    let urlString: String

    var body: some View {
        Group {
            if urlString.isEmpty {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("No Image")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
            } else {
                AppAsyncImage(urlString: urlString) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .overlay {
                                ProgressView()
                            }
                    }
                }
            }
        }
        .frame(width: 92, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AdminEditorPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct AdminEditorGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

private struct EditorValidationMessage: Identifiable {
    enum Kind {
        case warning
        case error

        var color: Color {
            switch self {
            case .warning:
                return .orange
            case .error:
                return .red
            }
        }

        var icon: String {
            switch self {
            case .warning:
                return "exclamationmark.triangle.fill"
            case .error:
                return "xmark.octagon.fill"
            }
        }
    }

    let id = UUID()
    let text: String
    let kind: Kind
}
