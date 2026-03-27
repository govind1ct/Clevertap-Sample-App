import SwiftUI

struct ProductDetailView: View {
    let product: Product

    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedImageIndex = 0
    @State private var selectedQuantity = 1
    @State private var isAddedToCart = false
    @State private var isAddedToWishlist = false
    @State private var showFullDescription = false

    private var hasDiscount: Bool {
        product.originalPrice > product.price
    }

    private var discountPercentage: Int {
        guard hasDiscount, product.originalPrice > 0 else { return 0 }
        return Int(((product.originalPrice - product.price) / product.originalPrice) * 100)
    }

    private var totalPrice: Double {
        product.price * Double(selectedQuantity)
    }

    private var imageURLs: [String] {
        if !product.images.isEmpty { return product.images }
        if let imageURL = product.imageURL, !imageURL.isEmpty { return [imageURL] }
        return []
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    mediaSection
                    headlineSection
                    editorialMetaStrip
                    storySection

                    if !product.benefits.isEmpty {
                        detailCluster(
                            title: "Benefits",
                            subtitle: "What this piece is known to bring into daily ritual.",
                            items: product.benefits,
                            tone: .warm
                        )
                    }

                    if !product.purposes.isEmpty {
                        detailCluster(
                            title: "Intentions",
                            subtitle: "Common reasons people choose this product.",
                            items: product.purposes,
                            tone: .ink
                        )
                    }

                    if !product.chakras.isEmpty {
                        detailCluster(
                            title: "Chakra Focus",
                            subtitle: "Traditional energetic associations for this piece.",
                            items: product.chakras,
                            tone: .mist
                        )
                    }

                    specificationsSection

                    if !product.careInstructions.isEmpty {
                        careSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 132)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            purchaseDock
        }
    }
}

private extension ProductDetailView {
    enum ClusterTone {
        case warm
        case ink
        case mist
    }

    var isDarkMode: Bool {
        colorScheme == .dark
    }

    var accentStart: Color {
        Color("CleverTapPrimary")
    }

    var accentEnd: Color {
        Color("CleverTapSecondary")
    }

    var canvasTop: Color {
        isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.10) : Color(red: 0.97, green: 0.95, blue: 0.92)
    }

    var canvasBottom: Color {
        isDarkMode ? Color(red: 0.11, green: 0.10, blue: 0.12) : Color(red: 0.93, green: 0.92, blue: 0.89)
    }

    var paper: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.72)
    }

    var elevatedPaper: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.86)
    }

    var border: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    var goldLine: Color {
        isDarkMode ? Color(red: 0.74, green: 0.63, blue: 0.39) : Color(red: 0.63, green: 0.50, blue: 0.25)
    }

    var primaryText: Color {
        isDarkMode ? Color.white.opacity(0.94) : Color.black.opacity(0.90)
    }

    var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.70) : Color.black.opacity(0.56)
    }

    var tertiaryText: Color {
        isDarkMode ? Color.white.opacity(0.48) : Color.black.opacity(0.38)
    }

    var stockTint: Color {
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

    var backgroundLayer: some View {
        LinearGradient(
            colors: [canvasTop, canvasBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Rectangle()
                .fill(isDarkMode ? Color.black.opacity(0.22) : Color.white.opacity(0.08))
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(goldLine.opacity(isDarkMode ? 0.18 : 0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 40)
                .offset(x: -90, y: -120)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(accentEnd.opacity(isDarkMode ? 0.12 : 0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 44)
                .offset(x: 80, y: -80)
        }
        .ignoresSafeArea()
    }

    var mediaSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selectedImageIndex) {
                    if imageURLs.isEmpty {
                        placeholderMedia
                            .tag(0)
                    } else {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                            mediaImage(url: url)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(elevatedPaper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(isDarkMode ? 0.20 : 0.08), radius: 16, y: 8)

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        if hasDiscount {
                            topPill(title: "\(discountPercentage)% off", tint: .white, fill: Color.red)
                        }
                        topPill(title: product.stockLabel, tint: stockTint, fill: stockTint.opacity(0.16))
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                            isAddedToWishlist.toggle()
                        }
                    } label: {
                        Image(systemName: isAddedToWishlist ? "heart.fill" : "heart")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isAddedToWishlist ? Color.red : primaryText)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }

            if imageURLs.count > 1 {
                imageIndexStrip
            }
        }
    }

    var placeholderMedia: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(paper)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(tertiaryText)
                    Text("Visuals coming soon")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(secondaryText)
                }
            }
    }

    func mediaImage(url: String) -> some View {
        AppAsyncImage(urlString: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(paper)
                    .overlay(ProgressView())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.30)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    var imageIndexStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedImageIndex = index
                        }
                    } label: {
                        AppAsyncImage(urlString: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(paper)
                            }
                        }
                        .frame(width: 56, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(index == selectedImageIndex ? goldLine : border, lineWidth: index == selectedImageIndex ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    var headlineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        categoryPill

                        if product.isFeaturedActive {
                            subtlePill(title: "Featured", tint: .orange)
                        }

                        if product.isNewLaunchActive {
                            subtlePill(title: "New", tint: .green)
                        }
                    }

                    Text(product.name)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(primaryText)
                        .lineLimit(3)

                    if let shortDescription = product.shortDescription, !shortDescription.isEmpty {
                        Text(shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("₹\(Int(product.price))")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(goldLine)

                    if hasDiscount {
                        Text("₹\(Int(product.originalPrice))")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(secondaryText)
                            .strikethrough()
                        Text("Save ₹\(Int(product.originalPrice - product.price))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }

            Rectangle()
                .fill(goldLine.opacity(0.35))
                .frame(width: 72, height: 1)

            HStack(spacing: 10) {
                metaValue(title: "Availability", value: product.availabilityMessage?.isEmpty == false ? product.availabilityMessage! : "Ready to ship")
                metaValue(title: "Category", value: product.category.capitalized)
            }
        }
        .padding(16)
        .background(elevatedPaper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    var editorialMetaStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                metaPill(icon: "shippingbox.fill", text: product.stockLabel, tint: stockTint)
                metaPill(icon: "bolt.fill", text: "Energy \(product.energyLevel)/5", tint: .yellow)
                metaPill(icon: "checkmark.seal.fill", text: "Verified quality", tint: .green)
            }
            .padding(.horizontal, 2)
        }
    }

    var storySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(eyebrow: "Editorial Note", title: "About this piece", detail: showFullDescription ? "Expanded" : "Condensed")

            Text(product.description)
                .font(.subheadline)
                .foregroundStyle(secondaryText)
                .lineLimit(showFullDescription ? nil : 5)
                .fixedSize(horizontal: false, vertical: true)

            Button(showFullDescription ? "Show less" : "Read more") {
                withAnimation(.easeInOut(duration: 0.24)) {
                    showFullDescription.toggle()
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(goldLine)
        }
        .padding(14)
        .background(paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    func detailCluster(title: String, subtitle: String, items: [String], tone: ClusterTone) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(eyebrow: "Collected Notes", title: title, detail: subtitle)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(clusterForeground(for: tone))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(clusterBackground(for: tone), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    func clusterForeground(for tone: ClusterTone) -> Color {
        switch tone {
        case .ink:
            return .white
        case .warm, .mist:
            return primaryText
        }
    }

    func clusterBackground(for tone: ClusterTone) -> some ShapeStyle {
        switch tone {
        case .warm:
            return AnyShapeStyle(goldLine.opacity(0.14))
        case .ink:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [accentStart, accentEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .mist:
            return AnyShapeStyle(Color.blue.opacity(0.12))
        }
    }

    var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(eyebrow: "Composition", title: "Specifications", detail: "Material and product details")

            if let specifications = product.specifications, !specifications.isEmpty {
                ForEach(specifications.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    specificationRow(title: key.capitalized, value: value)
                }
            } else {
                specificationRow(title: "Category", value: product.category.capitalized)
                specificationRow(title: "Energy", value: "\(product.energyLevel)/5")
                if let primaryChakra = product.chakras.first {
                    specificationRow(title: "Primary Chakra", value: primaryChakra)
                }
            }
        }
        .padding(14)
        .background(paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    func specificationRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tertiaryText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(border)
                .opacity(title == lastSpecificationTitle ? 0 : 1)
        }
    }

    var lastSpecificationTitle: String {
        if let specifications = product.specifications, let last = specifications.sorted(by: { $0.key < $1.key }).last?.key.capitalized {
            return last
        }
        if !product.chakras.isEmpty {
            return "Primary Chakra"
        }
        return "Energy"
    }

    var careSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(eyebrow: "Preservation", title: "Care Instructions", detail: "A little care keeps the finish intact")

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(goldLine)
                    .frame(width: 32, height: 32)
                    .background(goldLine.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(product.careInstructions)
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(goldLine.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(14)
        .background(paper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    var purchaseDock: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Total")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(secondaryText)
                    Text("₹\(Int(totalPrice))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(primaryText)
                }

                Spacer()

                Text(product.stockLabel)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(stockTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(stockTint.opacity(0.14), in: Capsule())
            }

            HStack(spacing: 10) {
                quantitySelector

                Button {
                    guard product.isPurchasable else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        cartManager.addToCart(product, quantity: selectedQuantity)
                        isAddedToCart = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAddedToCart = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isAddedToCart ? "checkmark.circle.fill" : (product.isPurchasable ? "bag.fill" : "slash.circle"))
                        Text(isAddedToCart ? "Added" : (product.isPurchasable ? "Add to Cart" : product.stockLabel))
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        LinearGradient(
                            colors: product.isPurchasable ? [accentStart, accentEnd] : [Color.gray.opacity(0.82), Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .disabled(!product.isPurchasable)
                .opacity(product.isPurchasable ? 1 : 0.72)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
                .overlay(border)
        }
    }

    var quantitySelector: some View {
        HStack(spacing: 10) {
            Button {
                if selectedQuantity > 1 {
                    selectedQuantity -= 1
                }
            } label: {
                quantityControlIcon(systemName: "minus")
            }
            .buttonStyle(.plain)
            .disabled(selectedQuantity <= 1)

            Text("\(selectedQuantity)")
                .font(.headline.weight(.bold))
                .foregroundStyle(primaryText)
                .frame(minWidth: 20)

            Button {
                if selectedQuantity < min(99, max(product.resolvedStockQuantity, 1)) {
                    selectedQuantity += 1
                }
            } label: {
                quantityControlIcon(systemName: "plus")
            }
            .buttonStyle(.plain)
            .disabled(selectedQuantity >= min(99, max(product.resolvedStockQuantity, 1)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(border, lineWidth: 1)
        )
    }

    func quantityControlIcon(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.bold))
            .foregroundStyle(primaryText)
            .frame(width: 30, height: 30)
            .background(elevatedPaper, in: Circle())
    }

    func sectionHeader(eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(tertiaryText)
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(primaryText)
            Text(detail)
                .font(.caption)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var categoryPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "seal.fill")
                .font(.caption2.weight(.bold))
            Text(product.category.capitalized)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(goldLine)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(goldLine.opacity(0.12), in: Capsule())
    }

    func metaValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(tertiaryText)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func metaPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(paper, in: Capsule())
        .overlay(
            Capsule()
                .stroke(border, lineWidth: 1)
        )
    }

    func topPill(title: String, tint: Color, fill: Color) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(fill, in: Capsule())
    }

    func subtlePill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: Product(
                name: "Rose Quartz Bracelet",
                description: "A calming crystal bracelet known for emotional healing, self-love, and balance. Designed with a quieter silhouette and polished finish, it is meant to feel personal rather than loud, and suitable for everyday wear.",
                shortDescription: "Handcrafted with natural stones and a polished premium finish.",
                price: 1499,
                originalPrice: 1999,
                purposes: ["Love", "Healing", "Calm"],
                category: "bracelet",
                chakras: ["Heart Chakra"],
                energyLevel: 4,
                images: [],
                imageURL: nil,
                benefits: ["Emotional balance", "Positive energy"],
                careInstructions: "Clean with a soft cloth, avoid harsh chemicals, and store separately to preserve the polish and elastic integrity.",
                isNewLaunch: true,
                isFeatured: true,
                merchandisingPriority: 10,
                isCategoryPinned: true,
                categorySortPriority: 8,
                homePlacementSlot: 1,
                campaignTags: ["gifting", "editor-pick"],
                featuredStartAt: nil,
                featuredEndAt: nil,
                newLaunchStartAt: nil,
                newLaunchEndAt: nil,
                specifications: ["Material": "Natural Quartz", "Weight": "30g"],
                searchKeywords: ["rose quartz", "bracelet"],
                createdAt: Date(),
                status: "active",
                stockQuantity: 12,
                lowStockThreshold: 3,
                availabilityMessage: "Ready to ship"
            )
        )
        .environmentObject(CartManager())
    }
}
