import SwiftUI

struct HomeHeroSection: View {
    let greetingText: String
    let firstName: String
    let title: String
    let subtitle: String
    let profileName: String
    let profilePhotoURL: String
    let offerCount: Int
    let featuredCount: Int
    let cartCount: Int
    let animateGreeting: Bool
    let accentStart: Color
    let accentEnd: Color
    let isDarkMode: Bool
    let titleFontName: String
    let bodyFontName: String
    let onResetOffers: () -> Void
    let onViewCart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(greetingText), \(firstName)")
                        .font(.custom(bodyFontName, size: 14))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .offset(y: animateGreeting ? 0 : 14)
                        .opacity(animateGreeting ? 1 : 0)

                    Text(title)
                        .font(.custom(titleFontName, size: 42))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .offset(y: animateGreeting ? 0 : 18)
                        .opacity(animateGreeting ? 1 : 0)

                    Text(subtitle)
                        .font(.custom(bodyFontName, size: 15))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineLimit(3)
                        .offset(y: animateGreeting ? 0 : 22)
                        .opacity(animateGreeting ? 1 : 0)
                }

                Spacer(minLength: 10)

                HomeAvatarView(
                    name: profileName,
                    photoURL: profilePhotoURL,
                    glow: .white
                )
            }

            HStack(spacing: 10) {
                Button(action: onResetOffers) {
                    Label("Live Offers", systemImage: "sparkles")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onViewCart) {
                    Label("View Cart", systemImage: "bag")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                HeroMetricView(title: "Offers", value: "\(offerCount)", caption: "active", isDarkMode: isDarkMode)
                HeroMetricView(title: "Featured", value: "\(featuredCount)", caption: "curated", isDarkMode: isDarkMode)
                HeroMetricView(title: "Cart", value: "\(cartCount)", caption: "ready", isDarkMode: isDarkMode)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    accentStart.opacity(0.94),
                    accentEnd.opacity(0.86),
                    Color.black.opacity(isDarkMode ? 0.24 : 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: accentStart.opacity(isDarkMode ? 0.18 : 0.22), radius: 30, y: 16)
    }
}

struct HomeSearchSection: View {
    let categories: [String]
    let selectedCategory: String
    let accentStart: Color
    let primaryText: Color
    let secondaryText: Color
    let headlineText: Color
    let categoryLabel: (String) -> String
    let categoryIcon: (String) -> String
    let onReset: () -> Void
    let onSelectCategory: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHOP BY")
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(secondaryText)
                    Text("Categories")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(headlineText)
                }

                Spacer()

                if selectedCategory != "All" {
                    Button(action: onReset) {
                        Text("Show All")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(accentStart)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 24) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            onSelectCategory(category)
                        } label: {
                            HomeCategoryCard(
                                title: categoryLabel(category),
                                systemImage: categoryIcon(category),
                                isSelected: selectedCategory == category,
                                accentStart: accentStart,
                                primaryText: primaryText,
                                secondaryText: secondaryText
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct HomeCampaignSection: View {
    let banners: [HeroBanner]
    @Binding var currentIndex: Int
    let bannerProgress: CGFloat
    let isDarkMode: Bool
    let titleFontName: String
    let bodyFontName: String
    let accentStart: Color
    let accentEnd: Color
    let surfaceBorder: Color
    let onBannerTap: (HeroBanner) -> Void

    var body: some View {
        Group {
            if !banners.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HomeSectionHeader(
                        eyebrow: "Campaigns",
                        title: "Moments Worth Opening",
                        detail: "\(banners.count) live stories"
                    )

                    VStack(spacing: 14) {
                        TabView(selection: $currentIndex) {
                            ForEach(Array(banners.enumerated()), id: \.offset) { index, banner in
                                HeroBannerCard(
                                    banner: banner,
                                    isDarkMode: isDarkMode,
                                    titleFontName: titleFontName,
                                    bodyFontName: bodyFontName,
                                    accentStart: accentStart,
                                    accentEnd: accentEnd,
                                    isActive: currentIndex == index,
                                    onPrimaryAction: {
                                        onBannerTap(banner)
                                    }
                                )
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: 286)

                        HomeStoriesProgressBar(
                            count: banners.count,
                            currentIndex: currentIndex,
                            progress: bannerProgress,
                            accent: accentStart,
                            track: surfaceBorder.opacity(0.55)
                        )
                    }
                }
            }
        }
    }
}

struct HomeSpotlightSection: View {
    let products: [Product]
    let title: String
    let subtitle: String
    let scrollOffset: CGFloat
    let namespace: Namespace.ID
    let badge: (Product) -> String
    let socialProof: (Product) -> String
    let isWishlisted: (Product) -> Bool
    let onToggleWishlist: (Product) -> Void
    let onOpenProduct: (Product) -> Void
    let onQuickView: (Product) -> Void
    let onQuickBuy: (Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(
                eyebrow: "Spotlight",
                title: title,
                detail: subtitle
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(products) { product in
                        FeaturedProductCard(
                            product: product,
                            badge: badge(product),
                            socialProof: socialProof(product),
                            isWishlisted: isWishlisted(product),
                            scrollOffset: scrollOffset,
                            onToggleWishlist: {
                                onToggleWishlist(product)
                            },
                            onOpenProduct: {
                                onOpenProduct(product)
                            },
                            onQuickView: {
                                onQuickView(product)
                            },
                            onQuickBuy: {
                                onQuickBuy(product)
                            }
                        )
                        .matchedTransitionIfAvailable(id: "featured-\(product.id ?? product.name)", in: namespace)
                        .transaction { transaction in
                            transaction.animation = .spring(response: 0.48, dampingFraction: 0.9)
                        }
                    }
                }
            }
        }
    }
}

struct HomeCollectionSection: View {
    let products: [Product]
    let selectedCategory: String
    let subtitle: String
    let scrollOffset: CGFloat
    let namespace: Namespace.ID
    let badge: (Product) -> String
    let socialProof: (Product) -> String
    let isWishlisted: (Product) -> Bool
    let onToggleWishlist: (Product) -> Void
    let onOpenProduct: (Product) -> Void
    let onQuickView: (Product) -> Void
    let onQuickBuy: (Product) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HomeSectionHeader(
                eyebrow: selectedCategory == "All" ? "Collection" : "Browsing",
                title: selectedCategory == "All" ? "Shop All" : selectedCategory,
                detail: subtitle
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 16
            ) {
                ForEach(products) { product in
                    GridProductCard(
                        product: product,
                        badge: badge(product),
                        socialProof: socialProof(product),
                        isWishlisted: isWishlisted(product),
                        scrollOffset: scrollOffset,
                        onToggleWishlist: {
                            onToggleWishlist(product)
                        },
                        onOpenProduct: {
                            onOpenProduct(product)
                        },
                        onQuickView: {
                            onQuickView(product)
                        },
                        onQuickBuy: {
                            onQuickBuy(product)
                        }
                    )
                    .matchedTransitionIfAvailable(id: "grid-\(product.id ?? product.name)", in: namespace)
                    .transaction { transaction in
                        transaction.animation = .spring(response: 0.48, dampingFraction: 0.9)
                    }
                }
            }
        }
    }
}

private struct HeroMetricView: View {
    let title: String
    let value: String
    let caption: String
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.72))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(isDarkMode ? 0.04 : 0.34), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct HomeAvatarView: View {
    let name: String
    let photoURL: String
    let glow: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(glow.opacity(0.20))
                .frame(width: 72, height: 72)
                .blur(radius: 16)

            Group {
                if !photoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    AppAsyncImage(urlString: photoURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            initialsAvatar
                        }
                    }
                } else {
                    initialsAvatar
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
        }
    }

    private var initialsAvatar: some View {
        ZStack {
            LinearGradient(
                colors: [glow.opacity(0.95), Color.white.opacity(0.30)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Text(initials)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        let value = String(letters)
        return value.isEmpty ? "U" : value.uppercased()
    }
}

private struct HomeCategoryCard: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let accentStart: Color
    let primaryText: Color
    let secondaryText: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isSelected ? accentStart.opacity(0.14) : Color.white.opacity(0.0))
                    .frame(width: 52, height: 52)

                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? accentStart : primaryText.opacity(0.68))
            }

            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? accentStart : secondaryText)
                .lineLimit(1)

            Capsule()
                .fill(accentStart.opacity(isSelected ? 1 : 0))
                .frame(width: 24, height: 3)
        }
        .frame(width: 74)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? 1.04 : 1)
        .opacity(isSelected ? 1 : 0.76)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
    }
}

private struct HomeStoriesProgressBar: View {
    let count: Int
    let currentIndex: Int
    let progress: CGFloat
    let accent: Color
    let track: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(track)
                        Capsule()
                            .fill(accent)
                            .frame(width: fillWidth(in: geometry.size.width, index: index))
                    }
                }
                .frame(height: 6)
            }
        }
        .frame(height: 6)
    }

    private func fillWidth(in totalWidth: CGFloat, index: Int) -> CGFloat {
        if index < currentIndex { return totalWidth }
        if index == currentIndex { return totalWidth * progress }
        return 0
    }
}

private struct HeroBannerCard: View {
    let banner: HeroBanner
    let isDarkMode: Bool
    let titleFontName: String
    let bodyFontName: String
    let accentStart: Color
    let accentEnd: Color
    let isActive: Bool
    let onPrimaryAction: () -> Void

    private var hasDestination: Bool {
        let linkedProductID = banner.linkedProductID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let campaignTag = banner.campaignTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let deepLink = banner.ctaDeepLink?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !linkedProductID.isEmpty || !campaignTag.isEmpty || !deepLink.isEmpty
    }

    private var backgroundStart: Color {
        colorFromHex(banner.backgroundHex) ?? accentStart
    }

    private var backgroundEnd: Color {
        colorFromHex(banner.accentHex) ?? accentEnd
    }

    var body: some View {
        GeometryReader { geometry in
            let minX = geometry.frame(in: .global).minX

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
                            Rectangle().fill(.clear)
                        }
                    }
                    .scaleEffect(1.1)
                    .offset(x: -minX * 0.08)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(isDarkMode ? 0.10 : 0.06),
                                Color.black.opacity(0.50)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        if let offerLabel = banner.offerLabel, !offerLabel.isEmpty {
                            heroChip(title: offerLabel)
                        }
                        heroChip(title: urgencyText)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(banner.title)
                            .font(.custom(titleFontName, size: 30))
                            .foregroundStyle(Color.white)
                            .lineLimit(2)

                        Text(banner.subtitle)
                            .font(.custom(bodyFontName, size: 14))
                            .foregroundStyle(Color.white.opacity(0.82))
                            .lineLimit(3)
                    }

                    HStack(spacing: 10) {
                        statPill(text: viewerText)

                        if let ctaText = banner.ctaText, !ctaText.isEmpty {
                            HStack(spacing: 8) {
                                Text(ctaText)
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(backgroundStart)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white, in: Capsule())
                        }
                    }
                }
                .padding(22)
            }
            .scaleEffect(isActive ? 1 : 0.985)
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.white.opacity(isDarkMode ? 0.10 : 0.16), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .onTapGesture {
                guard hasDestination else { return }
                onPrimaryAction()
            }
            .shadow(color: Color.black.opacity(isDarkMode ? 0.28 : 0.14), radius: 24, y: 14)
        }
    }

    private var urgencyText: String {
        guard let endAt = banner.endAt else { return "Fresh now" }
        let hours = max(Int(endAt.timeIntervalSinceNow / 3600), 1)
        return "Ends in \(hours) hrs"
    }

    private var viewerText: String {
        let seed = abs((banner.id ?? banner.title).hashValue % 70) + 18
        return "🔥 \(seed) users viewing"
    }

    private func heroChip(title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.16), in: Capsule())
    }

    private func statPill(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
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
