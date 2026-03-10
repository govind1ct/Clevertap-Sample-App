import Foundation

struct ThemeConfig: Decodable {
    let theme: ThemeIdentity
    let background: BackgroundConfig?
    let navigationBar: NavigationBarConfig?
    let cards: CardStyle?
    let buttons: ThemeButtonStyles?
    let typography: TypographyStyle?
    let icons: IconStyle?
    let banner: BannerStyle?
    let spacing: SpacingStyle?
    let animations: AnimationStyle?

    static let `default` = ThemeConfig(
        theme: ThemeIdentity(name: "default"),
        background: BackgroundConfig(type: "gradient", colors: ["#F5F7FB", "#E9EEF6", "#F8FAFF"]),
        navigationBar: NavigationBarConfig(textColor: "#0B0F18", glassOpacity: 0.15),
        cards: CardStyle(background: "#FFFFFF", borderColor: "#E4E8F0", cornerRadius: 20, shadowOpacity: 0.12),
        buttons: ThemeButtonStyles(
            primary: ThemeButtonStyle(background: "#3B5BDB", textColor: "#FFFFFF"),
            secondary: ThemeButtonStyle(background: "#111827", textColor: "#FFFFFF")
        ),
        typography: TypographyStyle(titleFont: "Georgia", bodyFont: "System", titleColor: "#0B0F18", bodyColor: "#4B5563"),
        icons: IconStyle(color: "#4B5563"),
        banner: BannerStyle(background: "#F3F4F6", textColor: "#111827"),
        spacing: SpacingStyle(section: 24, card: 16),
        animations: AnimationStyle(style: "smooth", duration: 0.35)
    )

    static let luxuryPreset = ThemeConfig(
        theme: ThemeIdentity(name: "luxury"),
        background: BackgroundConfig(type: "gradient", colors: ["#0F0F0F", "#1C1C1E", "#000000"]),
        navigationBar: NavigationBarConfig(textColor: "#D4AF37", glassOpacity: 0.28),
        cards: CardStyle(background: "#1A1A1A", borderColor: "#D4AF37", cornerRadius: 20, shadowOpacity: 0.35),
        buttons: ThemeButtonStyles(
            primary: ThemeButtonStyle(background: "#D4AF37", textColor: "#0B0F18"),
            secondary: ThemeButtonStyle(background: "#111111", textColor: "#D4AF37")
        ),
        typography: TypographyStyle(titleFont: "Georgia", bodyFont: "System", titleColor: "#E8D5A7", bodyColor: "#C7B48B"),
        icons: IconStyle(color: "#C7B48B"),
        banner: BannerStyle(background: "#1A1A1A", textColor: "#E8D5A7"),
        spacing: SpacingStyle(section: 26, card: 16),
        animations: AnimationStyle(style: "smooth", duration: 0.4)
    )
}

struct ThemeIdentity: Decodable {
    let name: String
}

struct BackgroundConfig: Decodable {
    let type: String
    let colors: [String]
}

struct NavigationBarConfig: Decodable {
    let textColor: String
    let glassOpacity: Double
}

struct CardStyle: Decodable {
    let background: String
    let borderColor: String
    let cornerRadius: Double
    let shadowOpacity: Double
}

struct ThemeButtonStyles: Decodable {
    let primary: ThemeButtonStyle
    let secondary: ThemeButtonStyle?
}

struct ThemeButtonStyle: Decodable {
    let background: String
    let textColor: String
}

struct TypographyStyle: Decodable {
    let titleFont: String
    let bodyFont: String
    let titleColor: String
    let bodyColor: String
}

struct IconStyle: Decodable {
    let color: String
}

struct BannerStyle: Decodable {
    let background: String
    let textColor: String
}

struct SpacingStyle: Decodable {
    let section: Double
    let card: Double
}

struct AnimationStyle: Decodable {
    let style: String
    let duration: Double
}
