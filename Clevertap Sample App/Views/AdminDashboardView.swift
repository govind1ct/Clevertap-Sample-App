import SwiftUI

struct AdminDashboardView: View {
    private enum Workspace: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case products = "Products"

        var id: String { rawValue }
    }

    @StateObject private var productService = ProductService(includeInactiveProducts: true)
    @StateObject private var adminProductService = AdminProductService()
    @StateObject private var orderService = AdminOrderService()
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

    var headerSummaryText: String {
        "Catalog \(catalogCount)  •  Visible \(visibleCount)  •  Low stock \(lowStockCount)  •  Selected \(selectedCount)"
    }

    var headerPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary").opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
                        Color(red: 0.05, green: 0.06, blue: 0.09),
                        Color(red: 0.08, green: 0.10, blue: 0.14),
                        Color(red: 0.10, green: 0.10, blue: 0.13)
                    ]
                    : [
                        Color(red: 0.96, green: 0.97, blue: 0.99),
                        Color(red: 0.92, green: 0.94, blue: 0.98),
                        Color(red: 0.98, green: 0.97, blue: 0.95)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Rectangle()
                .fill(isDarkMode ? Color.black.opacity(0.18) : Color.white.opacity(0.14))
                .ignoresSafeArea()

            Circle()
                .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.30 : 0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -150, y: -340)

            Circle()
                .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.26 : 0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(x: 180, y: -250)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(isDarkMode ? 0.04 : 0.22))
                .frame(width: 420, height: 240)
                .blur(radius: 40)
                .rotationEffect(.degrees(-18))
                .offset(x: 90, y: 260)
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
        HStack(spacing: 8) {
            ForEach(Workspace.allCases) { workspace in
                Button {
                    withAnimation(.easeInOut(duration: 0.20)) {
                        selectedWorkspace = workspace
                    }
                } label: {
                    AdminWorkspaceChip(
                        title: workspace.rawValue,
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
    }

    @ViewBuilder
    var workspaceContent: some View {
        switch selectedWorkspace {
        case .overview:
            overviewWorkspace
        case .products:
            productsWorkspace
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

    var sectionSurfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.82)
    }

    var sectionSurfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var sectionPrimaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.94)
    }

    var sectionSecondaryText: Color {
        isDarkMode ? Color.white.opacity(0.68) : Color.black.opacity(0.56)
    }

    var selectedWorkspaceTextColor: Color {
        isDarkMode ? Color.black.opacity(0.90) : .white
    }

    var headerButtonRow: some View {
        HStack(spacing: 10) {
            Button {
                showAddSheet = true
            } label: {
                Text("New Product")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(headerPrimaryGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                toggleSelectionMode()
            } label: {
                Text(isSelectionMode ? "Exit Select" : "Select Mode")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isDarkMode ? .white : Color("CleverTapPrimary"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(isDarkMode ? 0.08 : 0.55), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    var headerAuditButton: some View {
        HStack(spacing: 10) {
            NavigationLink {
                AdminAuditLogView()
            } label: {
                Text("Open Audit Trail")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(headerPrimaryGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            NavigationLink {
                AdminOrdersView()
            } label: {
                Text("Manage Orders")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color("CleverTapSecondary"), Color("CleverTapPrimary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    var selectionToolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(selectedProductIDs.count) selected")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(isDarkMode ? .white : .primary)

                Spacer()

                Button(selectedProductIDs.count == filteredProducts.compactMap(\.id).count ? "Clear Visible" : "Select Visible") {
                    toggleVisibleSelection()
                }
                .font(.caption.weight(.bold))
                .foregroundColor(isDarkMode ? .white.opacity(0.88) : Color("CleverTapPrimary"))
            }
            .padding(.horizontal, 2)

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
        .background(sectionSurfaceFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(sectionSurfaceBorder, lineWidth: 1)
        )
    }

    var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("At a glance")
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
            Text("Quick Actions")
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
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(sectionPrimaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(sectionSecondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(14)
        .background(tint.opacity(isDarkMode ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(tint)

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

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(sectionPrimaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(sectionSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 132, alignment: .leading)
        .background(tint.opacity(isDarkMode ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        VStack(spacing: 14) {
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
            .padding(.vertical, 12)
            .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    dashboardTag(title: isSelectionMode ? "Bulk mode on" : "Single edit mode", tint: isSelectionMode ? .orange : Color("CleverTapPrimary"))
                    dashboardTag(title: productService.isLoading ? "Syncing" : "Live catalog", tint: productService.isLoading ? .blue : .green)
                    dashboardTag(title: "\(filteredProducts.count) results", tint: .secondary, isNeutral: true)
                    dashboardTag(title: "\(outOfStockCount) unavailable", tint: .red)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(sectionSurfaceFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
            ProgressView("Loading products...")
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Unable to load products")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                productService.fetchProducts()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No products available")
                .font(.headline)
            Text("Add your first product to populate the catalog.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                productImage

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(product.name)
                                .font(.headline.weight(.bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            Text(product.category.capitalized)
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
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
                            .font(.headline.weight(.bold))
                            .foregroundColor(Color("CleverTapPrimary"))

                        if hasDiscount {
                            Text("₹\(Int(product.originalPrice))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .strikethrough()
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                summaryMetric(title: "Status", value: product.effectiveStatus.capitalized, tint: stockColor)
                summaryMetric(title: "Stock", value: "\(product.resolvedStockQuantity)", tint: stockColor)
                if !isSelectionMode {
                    summaryMetric(title: "Keywords", value: "\(product.searchKeywords.count)", tint: Color("CleverTapPrimary"))
                }
            }

            if !isSelectionMode {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        quickActionButton(label: "Edit", systemName: "square.and.pencil", tint: Color("CleverTapPrimary"), action: onEdit)
                        quickActionButton(label: product.isFeatured ? "Featured" : "Feature", systemName: product.isFeatured ? "star.fill" : "star", tint: .orange, action: onToggleFeatured)
                        quickActionButton(label: product.isNewLaunch ? "Launch" : "Mark Launch", systemName: "sparkles", tint: .green, action: onToggleNewLaunch)
                        quickActionButton(label: "Status", systemName: "arrow.triangle.2.circlepath", tint: stockColor, action: onCycleStatus)
                        quickActionButton(label: "Delete", systemName: "trash", tint: .red, action: onDelete)
                    }
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isDarkMode
                    ? [Color.white.opacity(0.09), Color.white.opacity(0.04)]
                    : [Color.white.opacity(0.90), Color.white.opacity(0.80)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.14 : 0.04), radius: 10, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            }
        }
    }

    var productImage: some View {
        AppAsyncImage(urlString: product.mainImageURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color("CleverTapPrimary").opacity(0.22), Color("CleverTapSecondary").opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "shippingbox.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.88))
                )
            }
        }
        .frame(width: 86, height: 102)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var cardBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
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
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(tint == Color("CleverTapPrimary") ? .primary : tint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func statusPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
    }

    var discountPill: some View {
        Text("\(discountPercent)% OFF")
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red, in: Capsule())
    }
}

private struct AdminWorkspaceChip: View {
    let title: String
    let isSelected: Bool
    let selectedTextColor: Color
    let secondaryTextColor: Color
    let surfaceFill: Color
    let surfaceBorder: Color

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(isSelected ? selectedTextColor : secondaryTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : surfaceBorder, lineWidth: 1)
            )
    }

    private var backgroundStyle: AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            return AnyShapeStyle(surfaceFill)
        }
    }
}


struct AdminProductEditorView: View {
    let title: String
    @State var form: AdminProductFormData
    let categoryOptions: [String]
    let purposeOptions: [String]
    let chakraOptions: [String]
    let benefitOptions: [String]
    let onSave: (AdminProductFormData) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showValidationAlert = false

    private var isValid: Bool {
        !form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var previewImageURL: String {
        let primary = form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !primary.isEmpty {
            return primary
        }

        let galleryImage = form.imagesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        return galleryImage ?? ""
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

        return messages
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
                        editorHeader
                        previewSection
                        validationSection
                        basicsSection
                        pricingSection
                        tagsSection
                        mediaSection
                        detailsSection
                        flagsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if isValid {
                            onSave(form)
                        } else {
                            showValidationAlert = true
                        }
                    }
                }
            }
            .alert("Missing required fields", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Name, category, and description are required.")
            }
        }
    }
}

private extension AdminProductEditorView {
    var editorHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("CleverTapPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())

            Text("Catalog Editor")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text("Update product content, pricing, and merchandising fields in one place.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var basicsSection: some View {
        AdminEditorSection(title: "Basics", subtitle: "Primary product identity and messaging.") {
            VStack(spacing: 12) {
                AdminEditorTextField(title: "Name", text: $form.name)
                AdminCategoryField(text: $form.category, options: categoryOptions)
                AdminEditorTextField(title: "Short Description", text: $form.shortDescription)
                AdminEditorTextField(title: "Description", text: $form.description, axis: .vertical, lineLimit: 4...7)
            }
        }
    }

    var previewSection: some View {
        AdminEditorSection(title: "Preview", subtitle: "Quick storefront snapshot before saving.") {
            HStack(alignment: .top, spacing: 14) {
                AdminEditorImagePreview(urlString: previewImageURL)

                VStack(alignment: .leading, spacing: 8) {
                    Text(form.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Product" : form.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(form.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No category" : form.category.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Text("₹\(Int(form.price))")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(Color("CleverTapPrimary"))

                        if form.originalPrice > form.price, form.originalPrice > 0 {
                            Text("₹\(Int(form.originalPrice))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .strikethrough()
                        }
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 6) {
                            editorPill(title: stockPreviewLabel, tint: stockPreviewColor)

                            if form.isFeatured {
                                editorPill(title: "Featured", tint: .orange)
                            }

                            if form.isNewLaunch {
                                editorPill(title: "New", tint: .green)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            editorPill(title: stockPreviewLabel, tint: stockPreviewColor)

                            if form.isFeatured {
                                editorPill(title: "Featured", tint: .orange)
                            }

                            if form.isNewLaunch {
                                editorPill(title: "New", tint: .green)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
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
        AdminEditorSection(title: "Pricing", subtitle: "Commercial values used across the storefront.") {
            VStack(spacing: 12) {
                AdminEditorNumberField(title: "Price", value: $form.price)
                AdminEditorNumberField(title: "Original Price", value: $form.originalPrice)
                AdminEditorIntegerField(title: "Stock Quantity", value: $form.stockQuantity)
                AdminEditorIntegerField(title: "Low Stock Threshold", value: $form.lowStockThreshold)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Energy Level")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(form.energyLevel)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("CleverTapPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                    }

                    Stepper("", value: $form.energyLevel, in: 0...10)
                        .labelsHidden()
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    var tagsSection: some View {
        AdminEditorSection(title: "Tags", subtitle: "Comma-separated values for discovery and targeting.") {
            VStack(spacing: 12) {
                AdminSmartListField(title: "Purposes", text: $form.purposesText, options: purposeOptions)
                AdminSmartListField(title: "Chakras", text: $form.chakrasText, options: chakraOptions)
                AdminSmartListField(title: "Benefits", text: $form.benefitsText, options: benefitOptions)
                AdminEditorTextField(title: "Search Keywords", text: $form.searchKeywordsText)
            }
        }
    }

    var mediaSection: some View {
        AdminEditorSection(title: "Media", subtitle: "Image URLs used in cards and detail pages.") {
            VStack(spacing: 12) {
                AdminEditorTextField(title: "Images", text: $form.imagesText, axis: .vertical, lineLimit: 3...5)
                AdminEditorTextField(title: "Primary Image URL", text: $form.imageURL, axis: .vertical, lineLimit: 2...4)
            }
        }
    }

    var detailsSection: some View {
        AdminEditorSection(title: "Details", subtitle: "Supporting content and specifications.") {
            VStack(spacing: 12) {
                AdminEditorTextField(title: "Care Instructions", text: $form.careInstructions, axis: .vertical, lineLimit: 3...5)
                AdminEditorTextField(title: "Specifications", text: $form.specificationsText, axis: .vertical, lineLimit: 3...5)
            }
        }
    }

    var flagsSection: some View {
        AdminEditorSection(title: "Flags", subtitle: "Merchandising controls for storefront visibility.") {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Picker("Status", selection: $form.status) {
                        Text("Draft").tag("draft")
                        Text("Active").tag("active")
                        Text("Archived").tag("archived")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                AdminEditorTextField(
                    title: "Availability Message",
                    text: $form.availabilityMessage,
                    axis: .vertical,
                    lineLimit: 2...4
                )

                Toggle(isOn: $form.isNewLaunch) {
                    AdminToggleLabel(title: "New Launch", subtitle: "Highlights the product as recently launched.")
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Toggle(isOn: $form.isFeatured) {
                    AdminToggleLabel(title: "Featured", subtitle: "Promotes the product in featured placements.")
                }
                .padding(14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
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
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct AdminCategoryField: View {
    @Binding var text: String
    let options: [String]

    private var filteredOptions: [String] {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return options }

        return options.filter { option in
            option.localizedCaseInsensitiveContains(trimmedText)
        }
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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
