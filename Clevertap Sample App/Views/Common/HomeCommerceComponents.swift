import SwiftUI

struct HomeSectionHeader: View {
    let eyebrow: String
    let title: String
    let detail: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.54) : Color.black.opacity(0.38))
                Text(title)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : Color.black.opacity(0.92))
            }

            Spacer()

            Text(detail)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.62) : Color.black.opacity(0.50))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct FeaturedProductCard: View {
    let product: Product
    let badge: String
    let socialProof: String
    let isWishlisted: Bool
    let scrollOffset: CGFloat
    let onToggleWishlist: () -> Void
    let onOpenProduct: () -> Void
    let onQuickView: () -> Void
    let onQuickBuy: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpenProduct) {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack(alignment: .topLeading) {
                        AppAsyncImage(urlString: product.mainImageURL) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .offset(y: scrollOffset * -0.05)
                            } else {
                                Color.gray.opacity(0.15)
                            }
                        }
                        .frame(height: 214)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                        HStack {
                            tag(text: badge)
                            Spacer()
                            iconButton(systemName: isWishlisted ? "heart.fill" : "heart", action: onToggleWishlist)
                        }
                        .padding(14)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(product.name)
                            .font(.custom(themeManager.titleFontName, size: 22))
                            .foregroundStyle(titleText)
                            .lineLimit(2)

                        Text(product.shortDescription ?? product.category.capitalized)
                            .font(.custom(themeManager.bodyFontName, size: 13))
                            .foregroundStyle(subtitleText)
                            .lineLimit(2)

                        Text(socialProof)
                            .font(.custom(themeManager.bodyFontName, size: 11))
                            .foregroundStyle(subtitleText)
                            .lineLimit(1)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("₹\(Int(product.price))")
                                .font(.custom(themeManager.titleFontName, size: 20))
                                .foregroundStyle(titleText)
                            if product.originalPrice > product.price {
                                Text("₹\(Int(product.originalPrice))")
                                    .font(.custom(themeManager.bodyFontName, size: 11))
                                    .strikethrough()
                                    .foregroundStyle(subtitleText)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .buttonStyle(ProductPressStyle())

            HStack(spacing: 10) {
                quickAction(title: "Preview", systemName: "eye.fill", action: onQuickView)
                quickAction(title: "Add", systemName: "bag.fill", action: onQuickBuy, isPrimary: true)
            }
        }
        .padding(14)
        .frame(width: 286)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.30),
                            Color.orange.opacity(0.10),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10), radius: 18, y: 12)
    }

    private func tag(text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.24), in: Capsule())
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.black.opacity(0.18), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func quickAction(title: String, systemName: String, action: @escaping () -> Void, isPrimary: Bool = false) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isPrimary ? primaryActionText : secondaryActionText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(actionBackground(isPrimary: isPrimary), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(actionBorder(isPrimary: isPrimary), lineWidth: isPrimary ? 0 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func actionBackground(isPrimary: Bool) -> Color {
        if isPrimary {
            return colorScheme == .dark ? Color.white.opacity(0.24) : Color.black.opacity(0.84)
        }
        return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }

    private func actionBorder(isPrimary: Bool) -> Color {
        if isPrimary {
            return .clear
        }
        return colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var primaryActionText: Color {
        .white
    }

    private var secondaryActionText: Color {
        colorScheme == .dark ? .white : Color.black.opacity(0.86)
    }

    private var cardFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.88),
                Color.white.opacity(colorScheme == .dark ? 0.04 : 0.72)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var titleText: Color {
        colorScheme == .dark ? .white : Color.black.opacity(0.92)
    }

    private var subtitleText: Color {
        colorScheme == .dark ? Color.white.opacity(0.66) : Color.black.opacity(0.52)
    }
}

struct GridProductCard: View {
    let product: Product
    let badge: String
    let socialProof: String
    let isWishlisted: Bool
    let scrollOffset: CGFloat
    let onToggleWishlist: () -> Void
    let onOpenProduct: () -> Void
    let onQuickView: () -> Void
    let onQuickBuy: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpenProduct) {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        productImage

                        VStack {
                            HStack {
                                badgeView
                                Spacer()
                                iconButton(systemName: isWishlisted ? "heart.fill" : "heart", action: onToggleWishlist)
                            }
                            Spacer()
                        }
                        .padding(10)
                    }

                    Text(product.category.capitalized)
                        .font(.custom(themeManager.bodyFontName, size: 11))
                        .foregroundStyle(categoryText)

                    Text(product.name)
                        .font(.custom(themeManager.titleFontName, size: 15))
                        .foregroundStyle(titleText)
                        .lineLimit(2)
                        .frame(minHeight: 40, alignment: .top)

                    Text(socialProof)
                        .font(.custom(themeManager.bodyFontName, size: 11))
                        .foregroundStyle(secondaryPriceText)
                        .lineLimit(1)

                    priceRow
                }
            }
            .buttonStyle(ProductPressStyle())

            HStack(spacing: 8) {
                compactAction(title: "Preview", systemName: "eye.fill", action: onQuickView)
                compactAction(title: "Add", systemName: "bag.fill", action: onQuickBuy, isPrimary: true)
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: cardShadow, radius: 14, y: 10)
    }

    private var productImage: some View {
        AppAsyncImage(urlString: product.mainImageURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .offset(y: scrollOffset * -0.035)
            } else {
                Color.gray.opacity(0.15)
            }
        }
        .frame(height: 156)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var badgeView: some View {
        Text(badge.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(titleText)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.60), in: Capsule())
    }

    private var priceRow: some View {
        HStack(spacing: 6) {
            Text("₹\(Int(product.price))")
                .font(.custom(themeManager.titleFontName, size: 16))
                .foregroundStyle(titleText)

            if product.originalPrice > product.price {
                Text("₹\(Int(product.originalPrice))")
                    .font(.custom(themeManager.bodyFontName, size: 11))
                    .foregroundStyle(secondaryPriceText)
                    .strikethrough()
            }
        }
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.bold))
                .foregroundStyle(titleText)
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func compactAction(title: String, systemName: String, action: @escaping () -> Void, isPrimary: Bool = false) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isPrimary ? Color.white : secondaryActionText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isPrimary
                    ? AnyShapeStyle(LinearGradient(colors: [accentColor, accentColor.opacity(0.82)], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(secondaryActionBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(secondaryActionBorder, lineWidth: isPrimary ? 0 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.78)
    }

    private var cardShadow: Color {
        Color.black.opacity(colorScheme == .dark ? 0.20 : 0.08)
    }

    private var accentColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.88) : Color("CleverTapPrimary")
    }

    private var secondaryActionText: Color {
        colorScheme == .dark ? titleText : Color.black.opacity(0.86)
    }

    private var secondaryActionBackground: Color {
        colorScheme == .dark ? categoryBackground : Color.black.opacity(0.05)
    }

    private var secondaryActionBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }
}

struct ProductPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .rotation3DEffect(.degrees(configuration.isPressed ? 4 : 0), axis: (x: 1, y: -1, z: 0))
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.18 : 0.08), radius: configuration.isPressed ? 16 : 8, y: configuration.isPressed ? 10 : 6)
            .animation(.spring(response: 0.34, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.04 : 0.10), radius: configuration.isPressed ? 4 : 10, y: configuration.isPressed ? 2 : 6)
            .animation(.spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}
