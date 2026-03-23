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
        guard hasDiscount else { return 0 }
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
                VStack(alignment: .leading, spacing: 18) {
                    heroSection
                    titleAndPriceSection
                    trustSection
                    descriptionSection

                    if !product.benefits.isEmpty {
                        chipSection(title: "Benefits", items: product.benefits, style: .success)
                    }

                    if !product.chakras.isEmpty {
                        chipSection(title: "Chakras", items: product.chakras, style: .brand)
                    }

                    if !product.purposes.isEmpty {
                        chipSection(title: "Purposes", items: product.purposes, style: .filled)
                    }

                    specificationsSection

                    if !product.careInstructions.isEmpty {
                        careSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 140)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
    }
}

private extension ProductDetailView {
    var isDarkMode: Bool {
        colorScheme == .dark
    }

    var accentStart: Color {
        Color("CleverTapPrimary")
    }

    var accentEnd: Color {
        Color("CleverTapSecondary")
    }

    var cardBackgroundStyle: AnyShapeStyle {
        if isDarkMode {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
        return AnyShapeStyle(Color.white.opacity(0.84))
    }

    var cardBorderColor: Color {
        isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.94)
    }

    var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.72) : Color.black.opacity(0.58)
    }

    var backgroundLayer: some View {
        LinearGradient(
            colors: isDarkMode
                ? [
                    Color(red: 0.07, green: 0.09, blue: 0.13),
                    Color(red: 0.10, green: 0.12, blue: 0.17),
                    Color(red: 0.08, green: 0.09, blue: 0.12)
                ]
                : [
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color(red: 0.94, green: 0.96, blue: 0.99),
                    Color(red: 0.99, green: 0.98, blue: 0.96)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Rectangle()
                .fill(isDarkMode ? Color.black.opacity(0.18) : Color.white.opacity(0.12))
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(accentStart.opacity(isDarkMode ? 0.24 : 0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 34)
                .offset(x: 90, y: -90)
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(accentEnd.opacity(isDarkMode ? 0.18 : 0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 40)
                .offset(x: -80, y: -120)
        }
        .ignoresSafeArea()
    }

    var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $selectedImageIndex) {
                if imageURLs.isEmpty {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                        .tag(0)
                } else {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        AppAsyncImage(urlString: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(.secondarySystemBackground))
                                    .overlay(ProgressView())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 420)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(cardBackgroundStyle)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDarkMode ? 0.22 : 0.08), radius: 16, y: 10)

            VStack(spacing: 10) {
                if hasDiscount {
                    Text("\(discountPercentage)% OFF")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red, in: Capsule())
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isAddedToWishlist.toggle()
                    }
                } label: {
                    Image(systemName: isAddedToWishlist ? "heart.fill" : "heart")
                        .font(.headline.weight(.bold))
                        .foregroundColor(isAddedToWishlist ? .red : primaryText)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(14)
        }
    }

    var titleAndPriceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(product.category.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(accentStart)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentStart.opacity(0.12), in: Capsule())

                if product.isFeaturedActive {
                    Text("Featured")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.14), in: Capsule())
                }

                if product.isNewLaunchActive {
                    Text("New")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.14), in: Capsule())
                }

                Text(product.stockLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(stockBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(stockBadgeColor.opacity(0.14), in: Capsule())
            }

            Text(product.name)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(primaryText)

            if let shortDescription = product.shortDescription, !shortDescription.isEmpty {
                Text(shortDescription)
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("₹\(Int(product.price))")
                        .font(.title.weight(.bold))
                        .foregroundColor(accentStart)

                    if hasDiscount {
                        Text("₹\(Int(product.originalPrice))")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(secondaryText)
                            .strikethrough()
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.stockLabel)
                        .font(.caption.weight(.bold))
                        .foregroundColor(stockBadgeColor)
                    Text(product.availabilityMessage?.isEmpty == false ? product.availabilityMessage! : "Ready to ship")
                        .font(.caption)
                        .foregroundColor(secondaryText)
                }
            }
        }
        .padding(18)
        .background(cardBackgroundStyle, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }

    var trustSection: some View {
        HStack(spacing: 10) {
            trustBadge(icon: "bolt.fill", text: "Energy \(product.energyLevel)/5", color: .yellow)
            trustBadge(icon: "shippingbox.fill", text: "Stock \(product.resolvedStockQuantity)", color: stockBadgeColor)
            trustBadge(icon: "checkmark.shield.fill", text: "Verified quality", color: .green)
        }
    }

    var stockBadgeColor: Color {
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

    func trustBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundColor(secondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.72),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailSectionHeader("About this piece")

            Text(product.description)
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .lineLimit(showFullDescription ? nil : 4)

            Button(showFullDescription ? "Show less" : "Read more") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFullDescription.toggle()
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(accentStart)
        }
        .padding(16)
        .background(cardBackgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }

    enum ChipStyle {
        case success
        case brand
        case filled
    }

    func chipSection(title: String, items: [String], style: ChipStyle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            detailSectionHeader(title)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(style == .filled ? .white : primaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(chipBackground(for: style), in: Capsule())
                }
            }
        }
        .padding(16)
        .background(cardBackgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }

    func chipBackground(for style: ChipStyle) -> some ShapeStyle {
        switch style {
        case .success:
            return AnyShapeStyle(Color.green.opacity(0.16))
        case .brand:
            return AnyShapeStyle(Color.blue.opacity(0.14))
        case .filled:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.39, blue: 0.87), Color(red: 0.31, green: 0.57, blue: 0.95)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }

    var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailSectionHeader("Specifications")

            if let specifications = product.specifications, !specifications.isEmpty {
                ForEach(specifications.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    specRow(title: key.capitalized, value: value)
                }
            } else {
                specRow(title: "Category", value: product.category.capitalized)
                specRow(title: "Energy", value: "\(product.energyLevel)/5")
                if let primaryChakra = product.chakras.first {
                    specRow(title: "Primary Chakra", value: primaryChakra)
                }
            }
        }
        .padding(16)
        .background(cardBackgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }

    func specRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(primaryText)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 5)
    }

    var careSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailSectionHeader("Care Instructions")

            Text(product.careInstructions)
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentStart.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(cardBackgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
    }

    var bottomActionBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Total")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(secondaryText)
                Spacer()
                Text("₹\(Int(totalPrice))")
                    .font(.title3.weight(.bold))
                    .foregroundColor(primaryText)
            }

            HStack(spacing: 14) {
                quantitySelector

                Button {
                    guard product.isPurchasable else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
                            colors: [accentStart, accentEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
                .disabled(!product.isPurchasable)
                .opacity(product.isPurchasable ? 1 : 0.7)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

    var quantitySelector: some View {
        HStack(spacing: 10) {
            Button {
                if selectedQuantity > 1 { selectedQuantity -= 1 }
            } label: {
                Image(systemName: "minus")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(primaryText)
                    .frame(width: 30, height: 30)
                    .background((isDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.90)), in: Circle())
            }

            Text("\(selectedQuantity)")
                .font(.subheadline.weight(.bold))
                .frame(minWidth: 20)

            Button {
                if selectedQuantity < 99 { selectedQuantity += 1 }
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(primaryText)
                    .frame(width: 30, height: 30)
                    .background((isDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.90)), in: Circle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.7),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    func detailSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline.weight(.bold))
            .foregroundColor(primaryText)
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: Product(
                name: "Rose Quartz Bracelet",
                description: "A calming crystal bracelet known for emotional healing, self-love, and balance.",
                shortDescription: "Handcrafted with natural stones",
                price: 1499,
                originalPrice: 1999,
                purposes: ["Love", "Healing", "Calm"],
                category: "bracelet",
                chakras: ["Heart Chakra"],
                energyLevel: 4,
                images: [],
                imageURL: nil,
                benefits: ["Emotional balance", "Positive energy"],
                careInstructions: "Clean with soft cloth and keep away from harsh chemicals.",
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
