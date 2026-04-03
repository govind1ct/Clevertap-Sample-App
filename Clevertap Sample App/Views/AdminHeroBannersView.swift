import SwiftUI
import PhotosUI
import UIKit

struct AdminHeroBannersView: View {
    @StateObject private var bannerService = HeroBannerService(includeInactiveBanners: true)
    @StateObject private var adminBannerService = AdminHeroBannerService()
    @StateObject private var productService = ProductService()
    @Environment(\.colorScheme) private var colorScheme

    @State private var showAddSheet = false
    @State private var editingBanner: HeroBanner?
    @State private var pendingDeleteBanner: HeroBanner?
    @State private var showDeleteConfirmation = false
    @State private var showServiceError = false

    private var sortedBanners: [HeroBanner] {
        bannerService.banners.sorted(by: bannerSortOrder)
    }

    var body: some View {
        VStack(spacing: 18) {
            headerCard

            if bannerService.isLoading {
                loadingState
            } else if let errorMessage = bannerService.errorMessage, bannerService.banners.isEmpty {
                errorState(errorMessage)
            } else if sortedBanners.isEmpty {
                emptyState
            } else {
                bannerList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AdminHeroBannerEditorView(
                title: "Add Hero Banner",
                form: AdminHeroBannerFormData(),
                availableProducts: productService.products
            ) { form in
                adminBannerService.createBanner(from: form) { result in
                    switch result {
                    case .success:
                        bannerService.fetchBanners()
                        showAddSheet = false
                    case .failure:
                        break
                    }
                }
            }
        }
        .sheet(item: $editingBanner) { banner in
            AdminHeroBannerEditorView(
                title: "Edit Hero Banner",
                form: AdminHeroBannerFormData(from: banner),
                availableProducts: productService.products
            ) { form in
                guard let bannerID = banner.id else { return }
                adminBannerService.updateBanner(bannerID: bannerID, data: form) { result in
                    switch result {
                    case .success:
                        bannerService.fetchBanners()
                        editingBanner = nil
                    case .failure:
                        break
                    }
                }
            }
        }
        .alert("Delete Hero Banner?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                guard let banner = pendingDeleteBanner, let bannerID = banner.id else { return }
                adminBannerService.deleteBanner(bannerID: bannerID, title: banner.title) { result in
                    switch result {
                    case .success:
                        bannerService.fetchBanners()
                    case .failure:
                        break
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(pendingDeleteBanner?.title ?? "This banner")
        }
        .alert("Banner Action Failed", isPresented: $showServiceError, presenting: adminBannerService.errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .task {
            if bannerService.banners.isEmpty {
                bannerService.fetchBanners()
            }
            if productService.products.isEmpty {
                productService.fetchProducts()
            }
        }
        .onChange(of: adminBannerService.errorMessage) { _, newValue in
            showServiceError = newValue != nil
        }
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var surfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.82)
    }

    private var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.94)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.68) : Color.black.opacity(0.56)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HERO BANNERS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(secondaryText)

                    Text("Campaign surfaces")
                        .font(.title3.weight(.black))
                        .foregroundStyle(primaryText)

                    Text("A faster control surface for homepage offers, priorities, and on/off state.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.black))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            LinearGradient(
                                colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    summaryChip("\(sortedBanners.count) total")
                    summaryChip("\(sortedBanners.filter(\.isActive).count) enabled")
                    summaryChip("\(sortedBanners.filter(\.isScheduledActive).count) live")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    private var bannerList: some View {
        LazyVStack(spacing: 14) {
            ForEach(Array(sortedBanners.enumerated()), id: \.element.id) { index, banner in
                AdminHeroBannerCard(
                    banner: banner,
                    isDarkMode: isDarkMode,
                    canMoveUp: index > 0,
                    canMoveDown: index < sortedBanners.count - 1,
                    onToggleActive: { isActive in
                        toggleBanner(banner, isActive: isActive)
                    },
                    onEdit: { editingBanner = banner },
                    onMoveUp: { moveBanner(at: index, direction: -1) },
                    onMoveDown: { moveBanner(at: index, direction: 1) },
                    onDelete: {
                        pendingDeleteBanner = banner
                        showDeleteConfirmation = true
                    }
                )
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 22)
                    .fill(surfaceFill)
                    .frame(height: 180)
                    .redacted(reason: .placeholder)
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                bannerService.fetchBanners()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 38))
                .foregroundStyle(secondaryText)
            Text("No hero banners yet")
                .font(.headline)
                .foregroundStyle(primaryText)
            Text("Create scheduled offers and hero slides for the homepage carousel.")
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
            Button("Create First Banner") {
                showAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    private func summaryChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(surfaceFill, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(surfaceBorder, lineWidth: 1)
            )
    }

    private func bannerSortOrder(_ lhs: HeroBanner, _ rhs: HeroBanner) -> Bool {
        if lhs.resolvedPriority != rhs.resolvedPriority {
            return lhs.resolvedPriority < rhs.resolvedPriority
        }
        return (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
    }

    private func moveBanner(at index: Int, direction: Int) {
        let targetIndex = index + direction
        guard sortedBanners.indices.contains(index), sortedBanners.indices.contains(targetIndex) else { return }

        let sourceBanner = sortedBanners[index]
        let targetBanner = sortedBanners[targetIndex]
        guard let sourceID = sourceBanner.id, let targetID = targetBanner.id else { return }

        adminBannerService.updateBannerPriority(
            bannerID: sourceID,
            title: sourceBanner.title,
            priority: targetBanner.resolvedPriority
        ) { sourceResult in
            switch sourceResult {
            case .success:
                adminBannerService.updateBannerPriority(
                    bannerID: targetID,
                    title: targetBanner.title,
                    priority: sourceBanner.resolvedPriority
                ) { targetResult in
                    if case .success = targetResult {
                        bannerService.fetchBanners()
                    }
                }
            case .failure:
                break
            }
        }
    }

    private func toggleBanner(_ banner: HeroBanner, isActive: Bool) {
        guard let bannerID = banner.id else { return }

        adminBannerService.updateBannerActiveState(
            bannerID: bannerID,
            title: banner.title,
            isActive: isActive
        ) { result in
            if case .success = result {
                bannerService.fetchBanners()
            }
        }
    }
}

private struct AdminHeroBannerCard: View {
    let banner: HeroBanner
    let isDarkMode: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onToggleActive: (Bool) -> Void
    let onEdit: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    private var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.94)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.68) : Color.black.opacity(0.56)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                AppAsyncImage(urlString: banner.resolvedMobileImageURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: [Color("CleverTapPrimary").opacity(0.35), Color("CleverTapSecondary").opacity(0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 92, height: 106)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(banner.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(primaryText)
                                .lineLimit(2)

                            Text(banner.subtitle)
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 6) {
                            statusBadge(title: banner.isScheduledActive ? "Live" : (banner.isActive ? "Scheduled" : "Disabled"), tint: banner.isScheduledActive ? .green : (banner.isActive ? .orange : .gray))
                            statusBadge(title: "P\(banner.resolvedPriority)", tint: Color("CleverTapPrimary"))
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if let offerLabel = banner.offerLabel, !offerLabel.isEmpty {
                                statusBadge(title: offerLabel, tint: .pink)
                            }
                            if let campaignTag = banner.campaignTag, !campaignTag.isEmpty {
                                statusBadge(title: campaignTag, tint: Color("CleverTapSecondary"))
                            }
                            destinationBadge
                        }
                    }

                    if let ctaText = banner.ctaText, !ctaText.isEmpty {
                        Text("CTA: \(ctaText)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(primaryText)
                            .lineLimit(1)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(secondaryText)

                    Text(scheduleSummary)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button {
                            onToggleActive(!banner.isActive)
                        } label: {
                            Label(banner.isActive ? "Turn Off" : "Turn On", systemImage: banner.isActive ? "pause.circle" : "play.circle")
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(banner.isActive ? .orange : .green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background((banner.isActive ? Color.orange : Color.green).opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(Color("CleverTapPrimary"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onMoveUp) {
                            Label("Up", systemImage: "arrow.up")
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(canMoveUp ? Color("CleverTapPrimary") : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color("CleverTapPrimary").opacity(canMoveUp ? 0.12 : 0.05), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMoveUp)

                        Button(action: onMoveDown) {
                            Label("Down", systemImage: "arrow.down")
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundColor(canMoveDown ? Color("CleverTapPrimary") : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color("CleverTapPrimary").opacity(canMoveDown ? 0.12 : 0.05), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMoveDown)

                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.12), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 2)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    private var scheduleSummary: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        switch (banner.startAt, banner.endAt) {
        case let (start?, end?):
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        case let (start?, nil):
            return "Starts \(formatter.string(from: start))"
        case let (nil, end?):
            return "Until \(formatter.string(from: end))"
        default:
            return "Always available"
        }
    }

    private func statusBadge(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
    }

    @ViewBuilder
    private var destinationBadge: some View {
        if let linkedProductID = banner.linkedProductID, !linkedProductID.isEmpty {
            statusBadge(title: "Product", tint: .blue)
        } else if let campaignTag = banner.campaignTag, !campaignTag.isEmpty {
            statusBadge(title: "Campaign", tint: .purple)
        } else if let deepLink = banner.ctaDeepLink, !deepLink.isEmpty {
            statusBadge(title: "Link", tint: .teal)
        }
    }
}

private struct AdminHeroBannerEditorView: View {
    private enum DestinationType: String, CaseIterable, Identifiable {
        case none = "None"
        case product = "Product"
        case campaign = "Campaign"
        case deepLink = "Deep Link"

        var id: String { rawValue }
    }

    let title: String
    @State var form: AdminHeroBannerFormData
    let availableProducts: [Product]
    let onSave: (AdminHeroBannerFormData) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var imageUploadService = AdminProductImageUploadService()

    @State private var selectedPrimaryImageItem: PhotosPickerItem?
    @State private var selectedMobileImageItem: PhotosPickerItem?
    @State private var mediaAlertMessage = ""
    @State private var showMediaAlert = false
    @State private var productSearchText = ""
    @State private var selectedDestinationType: DestinationType

    init(
        title: String,
        form: AdminHeroBannerFormData,
        availableProducts: [Product],
        onSave: @escaping (AdminHeroBannerFormData) -> Void
    ) {
        self.title = title
        self.availableProducts = availableProducts
        self.onSave = onSave
        _form = State(initialValue: form)
        _selectedDestinationType = State(initialValue: Self.destinationType(for: form))
    }

    private static func destinationType(for form: AdminHeroBannerFormData) -> DestinationType {
        if !form.linkedProductID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .product
        }
        if !form.campaignTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .campaign
        }
        if !form.ctaDeepLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .deepLink
        }
        return .none
    }

    private var filteredProducts: [Product] {
        let query = productSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return availableProducts.sorted { $0.name < $1.name } }
        return availableProducts
            .filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                ($0.id ?? "").localizedCaseInsensitiveContains(query) ||
                $0.category.localizedCaseInsensitiveContains(query)
            }
            .sorted { $0.name < $1.name }
    }

    private var selectedProductSummary: Product? {
        availableProducts.first(where: { $0.id == form.linkedProductID.trimmingCharacters(in: .whitespacesAndNewlines) })
    }

    private var previewTitle: String {
        let value = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Your hero headline" : value
    }

    private var previewSubtitle: String {
        let value = form.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Explain the offer or why this banner matters." : value
    }

    private var primaryImageURL: String {
        form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var mobileImageURL: String {
        form.mobileImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var destinationSummary: String {
        let linkedProduct = form.linkedProductID.trimmingCharacters(in: .whitespacesAndNewlines)
        let campaignTag = form.campaignTag.trimmingCharacters(in: .whitespacesAndNewlines)
        let deepLink = form.ctaDeepLink.trimmingCharacters(in: .whitespacesAndNewlines)

        if let selectedProductSummary {
            return "Opens product \(selectedProductSummary.name)"
        }
        if !linkedProduct.isEmpty { return "Opens product \(linkedProduct)" }
        if !campaignTag.isEmpty { return "Filters home/catalog by \(campaignTag)" }
        if !deepLink.isEmpty { return "Uses deep link \(deepLink)" }
        return "No destination selected yet"
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: {
                let value = form.backgroundHex.trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? Color("CleverTapPrimary") : Color(hex: value)
            },
            set: { newValue in
                form.backgroundHex = newValue.hexString ?? form.backgroundHex
            }
        )
    }

    private var accentColorBinding: Binding<Color> {
        Binding(
            get: {
                let value = form.accentHex.trimmingCharacters(in: .whitespacesAndNewlines)
                return value.isEmpty ? Color("CleverTapSecondary") : Color(hex: value)
            },
            set: { newValue in
                form.accentHex = newValue.hexString ?? form.accentHex
            }
        )
    }

    private var validationMessage: String? {
        if form.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Title is required."
        }
        if form.subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Subtitle is required."
        }
        if form.imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Image URL is required."
        }
        if form.hasSchedule, form.endAt < form.startAt {
            return "Schedule end must be after schedule start."
        }
        if form.priority < 0 {
            return "Priority must be 0 or greater."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    BannerPreviewCard(
                        title: previewTitle,
                        subtitle: previewSubtitle,
                        imageURL: mobileImageURL.isEmpty ? primaryImageURL : mobileImageURL,
                        offerLabel: form.offerLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                        offerCode: form.offerCode.trimmingCharacters(in: .whitespacesAndNewlines),
                        ctaText: form.ctaText.trimmingCharacters(in: .whitespacesAndNewlines),
                        backgroundHex: form.backgroundHex.trimmingCharacters(in: .whitespacesAndNewlines),
                        accentHex: form.accentHex.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } header: {
                    Text("Preview")
                } footer: {
                    Text("This is a close approximation of the card shown on the home hero carousel.")
                }

                Section {
                    BannerEditorField(
                        title: "Headline",
                        helper: "Use one strong line. Keep it short enough to fit on mobile.",
                        text: $form.title
                    )
                    BannerEditorField(
                        title: "Supporting Copy",
                        helper: "Add context for the offer, collection, or campaign.",
                        text: $form.subtitle,
                        axis: .vertical,
                        lineLimit: 2...4
                    )
                } header: {
                    Text("Message")
                }

                Section {
                    PhotosPicker(selection: $selectedPrimaryImageItem, matching: .images) {
                        BannerUploadButton(
                            title: primaryImageURL.isEmpty ? "Upload Hero Image" : "Replace Hero Image",
                            subtitle: "Main banner artwork used on larger layouts.",
                            systemImage: "photo.badge.plus"
                        )
                    }

                    BannerEditorField(
                        title: "Hero Image URL",
                        helper: "Required. This is the default banner image.",
                        text: $form.imageURL,
                        axis: .vertical,
                        lineLimit: 2...4
                    )

                    PhotosPicker(selection: $selectedMobileImageItem, matching: .images) {
                        BannerUploadButton(
                            title: mobileImageURL.isEmpty ? "Upload Mobile Image" : "Replace Mobile Image",
                            subtitle: "Optional. Use this when the mobile crop should differ.",
                            systemImage: "rectangle.portrait.badge.plus"
                        )
                    }

                    BannerEditorField(
                        title: "Mobile Image URL",
                        helper: "Optional. Leave empty to reuse the hero image.",
                        text: $form.mobileImageURL,
                        axis: .vertical,
                        lineLimit: 2...4
                    )

                    if imageUploadService.isUploading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Uploading selected image...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Media")
                }

                Section {
                    BannerEditorField(
                        title: "Offer Label",
                        helper: "Examples: Flat 20% Off, New Launch, Weekend Deal.",
                        text: $form.offerLabel
                    )
                    BannerEditorField(
                        title: "Offer Code",
                        helper: "Optional coupon or promo code shown as a chip.",
                        text: $form.offerCode
                    )
                    BannerEditorField(
                        title: "CTA Text",
                        helper: "Examples: Shop Now, Explore, View Offer.",
                        text: $form.ctaText
                    )
                } header: {
                    Text("Offer & CTA")
                }

                Section {
                    Picker("Destination Type", selection: $selectedDestinationType) {
                        ForEach(DestinationType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedDestinationType) { _, newValue in
                        switch newValue {
                        case .none:
                            form.linkedProductID = ""
                            form.campaignTag = ""
                            form.ctaDeepLink = ""
                        case .product:
                            form.campaignTag = ""
                            form.ctaDeepLink = ""
                        case .campaign:
                            form.linkedProductID = ""
                            form.ctaDeepLink = ""
                        case .deepLink:
                            form.linkedProductID = ""
                            form.campaignTag = ""
                        }
                    }

                    switch selectedDestinationType {
                    case .none:
                        Text("This banner is informational only. CTA can still be shown, but no destination will be triggered.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                    case .product:
                        TextField("Search products by name, id, or category", text: $productSearchText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        if let selectedProductSummary {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Selected Product")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(selectedProductSummary.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(selectedProductSummary.id ?? "Missing ID")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if availableProducts.isEmpty {
                            Text("No products are loaded yet. Product destination requires catalog data.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(filteredProducts.prefix(8)) { product in
                                        Button {
                                            form.linkedProductID = product.id ?? ""
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(product.name)
                                                        .font(.subheadline.weight(.semibold))
                                                    Text(product.id ?? "Missing ID")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                if form.linkedProductID == product.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundStyle(Color("CleverTapPrimary"))
                                                }
                                            }
                                            .padding(10)
                                            .background(Color("CleverTapPrimary").opacity(form.linkedProductID == product.id ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .frame(maxHeight: 240)
                        }

                    case .campaign:
                        BannerEditorField(
                            title: "Campaign Tag",
                            helper: "Use this to drive search/filter behavior from the banner tap.",
                            text: $form.campaignTag
                        )

                    case .deepLink:
                        BannerEditorField(
                            title: "CTA Deep Link",
                            helper: "Supported values: cart, products, category:<name>, search:<term>.",
                            text: $form.ctaDeepLink
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Destinations")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    destinationPresetButton("Cart", value: "cart")
                                    destinationPresetButton("All Products", value: "products")
                                    destinationPresetButton("Search Gifts", value: "search:gifts")
                                    destinationPresetButton("Category: Jewelry", value: "category:jewelry")
                                }
                            }
                        }
                    }

                    LabeledContent("Destination") {
                        Text(destinationSummary)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Destination")
                } footer: {
                    Text("Choose one destination type. Product opens a specific item, Campaign applies a search/filter, and Deep Link handles routes like cart, products, category:jewelry, or search:gifts.")
                }

                Section {
                    ColorPicker("Background Color", selection: backgroundColorBinding, supportsOpacity: false)
                    ColorPicker("Accent Color", selection: accentColorBinding, supportsOpacity: false)
                    BannerEditorField(
                        title: "Background Hex",
                        helper: "Optional brand/background color, for example #0F4C81.",
                        text: $form.backgroundHex
                    )
                    BannerEditorField(
                        title: "Accent Hex",
                        helper: "Optional secondary color used in the banner gradient.",
                        text: $form.accentHex
                    )
                } header: {
                    Text("Visual Style")
                }

                Section {
                    Toggle("Active", isOn: $form.isActive)
                    Stepper(value: $form.priority, in: 0...999) {
                        HStack {
                            Text("Priority")
                            Spacer()
                            Text("\(form.priority)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle("Schedule Banner", isOn: $form.hasSchedule)
                    if form.hasSchedule {
                        DatePicker("Starts", selection: $form.startAt, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("Ends", selection: $form.endAt, displayedComponents: [.date, .hourAndMinute])
                    }
                } header: {
                    Text("Publishing")
                } footer: {
                    Text("Lower priority values appear earlier in the carousel.")
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(form)
                    }
                    .disabled(validationMessage != nil || imageUploadService.isUploading)
                }
            }
            .onChange(of: selectedPrimaryImageItem != nil) { _, hasSelection in
                guard hasSelection else { return }
                Task {
                    await handleImageSelection(item: selectedPrimaryImageItem, kind: "hero_primary", assignToMobileField: false)
                }
            }
            .onChange(of: selectedMobileImageItem != nil) { _, hasSelection in
                guard hasSelection else { return }
                Task {
                    await handleImageSelection(item: selectedMobileImageItem, kind: "hero_mobile", assignToMobileField: true)
                }
            }
            .alert("Image Upload", isPresented: $showMediaAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(mediaAlertMessage)
            }
        }
    }

    private func handleImageSelection(item: PhotosPickerItem?, kind: String, assignToMobileField: Bool) async {
        guard let item else { return }
        defer {
            if assignToMobileField {
                selectedMobileImageItem = nil
            } else {
                selectedPrimaryImageItem = nil
            }
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw AdminProductImageUploadError.processingFailed
            }

            let uploadedURL = try await imageUploadService.uploadProductImage(image, kind: kind)
            await MainActor.run {
                if assignToMobileField {
                    form.mobileImageURL = uploadedURL
                } else {
                    form.imageURL = uploadedURL
                }
            }
        } catch {
            await MainActor.run {
                mediaAlertMessage = error.localizedDescription
                showMediaAlert = true
            }
        }
    }

    private func destinationPresetButton(_ title: String, value: String) -> some View {
        Button {
            selectedDestinationType = .deepLink
            form.ctaDeepLink = value
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color("CleverTapPrimary").opacity(form.ctaDeepLink == value ? 0.16 : 0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct BannerEditorField: View {
    let title: String
    let helper: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int> = 1...1

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(helper)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: $text, axis: axis)
                .lineLimit(lineLimit)
        }
        .padding(.vertical, 4)
    }
}

private struct BannerUploadButton: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundColor(Color("CleverTapPrimary"))
                .frame(width: 36, height: 36)
                .background(Color("CleverTapPrimary").opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct BannerPreviewCard: View {
    let title: String
    let subtitle: String
    let imageURL: String
    let offerLabel: String
    let offerCode: String
    let ctaText: String
    let backgroundHex: String
    let accentHex: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [resolvedBackgroundColor, resolvedAccentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                AppAsyncImage(urlString: imageURL) { phase in
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
                        colors: [Color.black.opacity(0.08), Color.black.opacity(0.48)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    if !offerLabel.isEmpty {
                        previewChip(offerLabel)
                    }
                    if !offerCode.isEmpty {
                        previewChip(offerCode)
                    }
                }

                Spacer(minLength: 0)

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(3)

                if !ctaText.isEmpty {
                    Text(ctaText)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(resolvedBackgroundColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white, in: Capsule())
                }
            }
            .padding(20)
        }
        .frame(height: 220)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private var resolvedBackgroundColor: Color {
        colorFromHex(backgroundHex) ?? Color("CleverTapPrimary")
    }

    private var resolvedAccentColor: Color {
        colorFromHex(accentHex) ?? Color("CleverTapSecondary")
    }

    private func previewChip(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.14), in: Capsule())
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
}

private extension Color {
    var hexString: String? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }

        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}

#Preview {
    NavigationStack {
        AdminHeroBannersView()
            .padding()
    }
}
