import Foundation
import CleverTapSDK

@MainActor
final class CleverTapProductExperiencesService: ObservableObject {
    static let shared = CleverTapProductExperiencesService()
    private static let featureEnabledUserDefaultsKey = "product_experiences_feature_enabled"

    static var isFeatureEnabled: Bool {
        if UserDefaults.standard.object(forKey: featureEnabledUserDefaultsKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: featureEnabledUserDefaultsKey)
    }

    enum DemoPreset {
        case luxuryLaunch
        case festiveSale
        case reset
    }

    @Published private(set) var homeHeaderTitle: String = "Today"
    @Published private(set) var homeHeaderSubtitle: String = "Discover something beautiful."
    @Published private(set) var featuredSectionTitle: String = "Featured"
    @Published private(set) var showFeaturedSection: Bool = true
    @Published private(set) var maxFeaturedProducts: Int = 8
    @Published private(set) var hasFetchedVariables: Bool = false
    @Published private(set) var isDemoModeLocked: Bool = false
    @Published private(set) var isFeatureEnabled: Bool = true

    private var homeHeaderTitleVar: CleverTapSDK.Var?
    private var homeHeaderSubtitleVar: CleverTapSDK.Var?
    private var featuredSectionTitleVar: CleverTapSDK.Var?
    private var showFeaturedSectionVar: CleverTapSDK.Var?
    private var maxFeaturedProductsVar: CleverTapSDK.Var?

    private let defaultHeaderTitle = "Today"
    private let defaultHeaderSubtitle = "Discover something beautiful."
    private let defaultFeaturedSectionTitle = "Featured"
    private let defaultShowFeaturedSection = true
    private let defaultMaxFeaturedProducts: Int32 = 8
    private let demoModeLockUserDefaultsKey = "product_experiences_demo_mode_locked"
    private var hasRegisteredCallbacks = false

    private init() {
        isFeatureEnabled = Self.isFeatureEnabled
        isDemoModeLocked = UserDefaults.standard.bool(forKey: demoModeLockUserDefaultsKey)
        setupVariables()
        registerCallbacks()
    }

    private func setupVariables() {
        guard isFeatureEnabled else {
            applyDefaultValues()
            return
        }

        homeHeaderTitleVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_header_title",
            string: defaultHeaderTitle
        )
        homeHeaderSubtitleVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_header_subtitle",
            string: defaultHeaderSubtitle
        )
        featuredSectionTitleVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_featured_section_title",
            string: defaultFeaturedSectionTitle
        )
        showFeaturedSectionVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_show_featured_section",
            boolean: defaultShowFeaturedSection
        )
        maxFeaturedProductsVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_max_featured_products",
            integer: defaultMaxFeaturedProducts
        )

        applyCurrentValues()
    }

    private func registerCallbacks() {
        guard isFeatureEnabled, !hasRegisteredCallbacks else { return }
        hasRegisteredCallbacks = true

        CleverTap.sharedInstance()?.onVariablesChanged { [weak self] in
            Task { @MainActor in
                guard self?.isDemoModeLocked == false else { return }
                self?.applyCurrentValues()
            }
        }

        homeHeaderTitleVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                guard self?.isDemoModeLocked == false else { return }
                self?.applyCurrentValues()
            }
        }
        homeHeaderSubtitleVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                guard self?.isDemoModeLocked == false else { return }
                self?.applyCurrentValues()
            }
        }
        featuredSectionTitleVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                guard self?.isDemoModeLocked == false else { return }
                self?.applyCurrentValues()
            }
        }
        showFeaturedSectionVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                guard self?.isDemoModeLocked == false else { return }
                self?.applyCurrentValues()
            }
        }
        maxFeaturedProductsVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                guard self?.isDemoModeLocked == false else { return }
                self?.applyCurrentValues()
            }
        }
    }

    private func applyCurrentValues() {
        homeHeaderTitle = homeHeaderTitleVar?.stringValue ?? defaultHeaderTitle
        homeHeaderSubtitle = homeHeaderSubtitleVar?.stringValue ?? defaultHeaderSubtitle
        featuredSectionTitle = featuredSectionTitleVar?.stringValue ?? defaultFeaturedSectionTitle
        showFeaturedSection = showFeaturedSectionVar?.value as? Bool ?? defaultShowFeaturedSection

        let configuredMax = maxFeaturedProductsVar?.numberValue?.intValue ?? Int(defaultMaxFeaturedProducts)
        maxFeaturedProducts = max(1, configuredMax)
    }

    private func applyDefaultValues() {
        homeHeaderTitle = defaultHeaderTitle
        homeHeaderSubtitle = defaultHeaderSubtitle
        featuredSectionTitle = defaultFeaturedSectionTitle
        showFeaturedSection = defaultShowFeaturedSection
        maxFeaturedProducts = Int(defaultMaxFeaturedProducts)
    }

    func fetchVariables(completion: ((Bool) -> Void)? = nil) {
        guard isFeatureEnabled else {
            hasFetchedVariables = false
            applyDefaultValues()
            completion?(false)
            return
        }

        if isDemoModeLocked {
            completion?(false)
            return
        }

        guard let cleverTap = CleverTap.sharedInstance() else {
            hasFetchedVariables = false
            completion?(false)
            return
        }

        var didComplete = false
        let resolve: (Bool) -> Void = { [weak self] success in
            guard !didComplete else { return }
            didComplete = true
            Task { @MainActor in
                self?.hasFetchedVariables = success
                if success {
                    self?.applyCurrentValues()
                }
                completion?(success)
            }
        }

        cleverTap.fetchVariables { success in
            resolve(success)
        }

        // Prevent UI from waiting forever if SDK callback is not delivered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            resolve(false)
        }
    }

    func syncVariablesInDebugBuild() {
        guard isFeatureEnabled else { return }
        guard !isDemoModeLocked else { return }
        #if DEBUG
        CleverTap.sharedInstance()?.syncVariables()
        #endif
    }

    func applyDemoPreset(_ preset: DemoPreset) {
        guard isFeatureEnabled else { return }
        switch preset {
        case .luxuryLaunch:
            homeHeaderTitle = "Luxury Launch"
            homeHeaderSubtitle = "Curated picks for premium shoppers."
            featuredSectionTitle = "Signature Collection"
            showFeaturedSection = true
            maxFeaturedProducts = 4
        case .festiveSale:
            homeHeaderTitle = "Festive Specials"
            homeHeaderSubtitle = "Limited-time celebration offers."
            featuredSectionTitle = "Trending Offers"
            showFeaturedSection = true
            maxFeaturedProducts = 6
        case .reset:
            homeHeaderTitle = defaultHeaderTitle
            homeHeaderSubtitle = defaultHeaderSubtitle
            featuredSectionTitle = defaultFeaturedSectionTitle
            showFeaturedSection = defaultShowFeaturedSection
            maxFeaturedProducts = Int(defaultMaxFeaturedProducts)
        }

        hasFetchedVariables = true
    }

    func setFeatureEnabled(_ enabled: Bool) {
        isFeatureEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.featureEnabledUserDefaultsKey)

        if enabled {
            setupVariables()
            registerCallbacks()
            hasFetchedVariables = false
            if !isDemoModeLocked {
                fetchVariables()
            }
        } else {
            hasFetchedVariables = false
            isDemoModeLocked = false
            UserDefaults.standard.set(false, forKey: demoModeLockUserDefaultsKey)
            applyDefaultValues()
        }
    }

    func setDemoModeLocked(_ isLocked: Bool) {
        guard isFeatureEnabled else {
            isDemoModeLocked = false
            UserDefaults.standard.set(false, forKey: demoModeLockUserDefaultsKey)
            return
        }
        isDemoModeLocked = isLocked
        UserDefaults.standard.set(isLocked, forKey: demoModeLockUserDefaultsKey)
    }
}
