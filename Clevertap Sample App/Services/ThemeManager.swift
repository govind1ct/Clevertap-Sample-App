import Foundation
import SwiftUI
import CleverTapSDK

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var theme: ThemeConfig = .default
    @Published private(set) var isLuxuryActive: Bool = false

    private let themeKey = "home_theme_config"
    private let luxuryFlagKey = "home_theme_luxury_active"

    private init() {
        isLuxuryActive = false
        UserDefaults.standard.set(false, forKey: luxuryFlagKey)
        loadThemeFromCleverTap()
    }

    func loadThemeFromCleverTap() {
        guard isLuxuryActive else {
            theme = .default
            return
        }
        guard let cleverTap = CleverTap.sharedInstance(),
              let config = cleverTap.productConfig as AnyObject? else {
            theme = .default
            return
        }

        if let configValue = themeJSONString(from: config),
           let data = configValue.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(ThemeConfig.self, from: data) {
            theme = decoded
            return
        }

        theme = .luxuryPreset
    }

    func registerConfigListener() {
        guard let config = CleverTap.sharedInstance()?.productConfig as AnyObject? else { return }

        let didFetch = NSSelectorFromString("setProductConfigDidFetchCallback:")
        if config.responds(to: didFetch) {
            _ = config.perform(didFetch, with: { [weak self] in
                Task { @MainActor in
                    self?.loadThemeFromCleverTap()
                }
            })
        }

        let didActivate = NSSelectorFromString("setProductConfigDidActivateCallback:")
        if config.responds(to: didActivate) {
            _ = config.perform(didActivate, with: { [weak self] in
                Task { @MainActor in
                    self?.loadThemeFromCleverTap()
                }
            })
        }
    }

    func refreshFromCleverTap() {
        guard let config = CleverTap.sharedInstance()?.productConfig as AnyObject? else {
            theme = .default
            return
        }

        let fetchAndActivate = NSSelectorFromString("fetchAndActivate")
        let fetch = NSSelectorFromString("fetch")
        let activate = NSSelectorFromString("activate")

        if config.responds(to: fetchAndActivate) {
            _ = config.perform(fetchAndActivate)
        } else {
            if config.responds(to: fetch) {
                _ = config.perform(fetch)
            }
            if config.responds(to: activate) {
                _ = config.perform(activate)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            Task { @MainActor in
                self.loadThemeFromCleverTap()
            }
        }
    }

    func setLuxuryActive(_ isActive: Bool) {
        isLuxuryActive = isActive
        UserDefaults.standard.set(isActive, forKey: luxuryFlagKey)
        loadThemeFromCleverTap()
    }

    private func themeJSONString(from config: AnyObject) -> String? {
        let selectors = [
            "getStringForKey:",
            "stringForKey:",
            "getString:",
            "getValueForKey:",
            "getValue:",
            "get:"
        ]

        for name in selectors {
            let selector = NSSelectorFromString(name)
            guard config.responds(to: selector) else { continue }
            guard let unmanaged = config.perform(selector, with: themeKey) else { continue }
            let value = unmanaged.takeUnretainedValue()

            if let stringValue = value as? String {
                return stringValue
            }
            if let stringValue = value as? NSString {
                return stringValue as String
            }
            if let dict = value as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: dict),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
        }
        return nil
    }

    var backgroundGradient: [Color] {
        guard let background = theme.background, background.type == "gradient" else {
            return [Color(hex: "#F5F7FB"), Color(hex: "#E9EEF6"), Color(hex: "#F8FAFF")]
        }
        let colors = background.colors.compactMap { Color(hex: $0) }
        return colors.isEmpty
            ? [Color(hex: "#F5F7FB"), Color(hex: "#E9EEF6"), Color(hex: "#F8FAFF")]
            : colors
    }

    var navigationTextColor: Color {
        Color(hex: theme.navigationBar?.textColor ?? "#0B0F18")
    }

    var navigationGlassOpacity: Double {
        theme.navigationBar?.glassOpacity ?? 0.15
    }

    var cardBackground: Color {
        Color(hex: theme.cards?.background ?? "#FFFFFF")
    }

    var cardBorder: Color {
        Color(hex: theme.cards?.borderColor ?? "#E4E8F0")
    }

    var cardCornerRadius: Double {
        theme.cards?.cornerRadius ?? 20
    }

    var cardShadowOpacity: Double {
        theme.cards?.shadowOpacity ?? 0.12
    }

    var primaryButtonBackground: Color {
        Color(hex: theme.buttons?.primary.background ?? "#3B5BDB")
    }

    var primaryButtonText: Color {
        Color(hex: theme.buttons?.primary.textColor ?? "#FFFFFF")
    }

    var secondaryButtonBackground: Color {
        Color(hex: theme.buttons?.secondary?.background ?? "#111827")
    }

    var secondaryButtonText: Color {
        Color(hex: theme.buttons?.secondary?.textColor ?? "#FFFFFF")
    }

    var titleTextColor: Color {
        Color(hex: theme.typography?.titleColor ?? "#0B0F18")
    }

    var bodyTextColor: Color {
        Color(hex: theme.typography?.bodyColor ?? "#4B5563")
    }

    var titleFontName: String {
        theme.typography?.titleFont ?? "Georgia"
    }

    var bodyFontName: String {
        theme.typography?.bodyFont ?? "System"
    }

    var sectionSpacing: Double {
        theme.spacing?.section ?? 24
    }

    var cardSpacing: Double {
        theme.spacing?.card ?? 16
    }

    var animationDuration: Double {
        theme.animations?.duration ?? 0.35
    }
}
