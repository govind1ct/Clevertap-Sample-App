import Foundation
import CleverTapSDK

@MainActor
final class CleverTapProductExperiencesService: ObservableObject {
    static let shared = CleverTapProductExperiencesService()

    @Published private(set) var homeHeaderTitle: String = "Today"
    @Published private(set) var homeHeaderSubtitle: String = "Discover something beautiful."
    @Published private(set) var featuredSectionTitle: String = "Featured"
    @Published private(set) var showFeaturedSection: Bool = true
    @Published private(set) var maxFeaturedProducts: Int = 8
    @Published private(set) var hasFetchedVariables: Bool = false

    private var homeHeaderTitleVar: CleverTapSDK.Var?
    private var homeHeaderSubtitleVar: CleverTapSDK.Var?
    private var featuredSectionTitleVar: CleverTapSDK.Var?
    private var showFeaturedSectionVar: CleverTapSDK.Var?
    private var maxFeaturedProductsVar: CleverTapSDK.Var?

    private init() {
        setupVariables()
        registerCallbacks()
    }

    private func setupVariables() {
        homeHeaderTitleVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_header_title",
            string: "Today"
        )
        homeHeaderSubtitleVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_header_subtitle",
            string: "Discover something beautiful."
        )
        featuredSectionTitleVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_featured_section_title",
            string: "Featured"
        )
        showFeaturedSectionVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_show_featured_section",
            boolean: true
        )
        maxFeaturedProductsVar = CleverTap.sharedInstance()?.defineVar(
            name: "home_max_featured_products",
            integer: 8
        )

        applyCurrentValues()
    }

    private func registerCallbacks() {
        CleverTap.sharedInstance()?.onVariablesChanged { [weak self] in
            Task { @MainActor in
                self?.applyCurrentValues()
            }
        }

        homeHeaderTitleVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                self?.applyCurrentValues()
            }
        }
        homeHeaderSubtitleVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                self?.applyCurrentValues()
            }
        }
        featuredSectionTitleVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                self?.applyCurrentValues()
            }
        }
        showFeaturedSectionVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                self?.applyCurrentValues()
            }
        }
        maxFeaturedProductsVar?.onValueChanged { [weak self] in
            Task { @MainActor in
                self?.applyCurrentValues()
            }
        }
    }

    private func applyCurrentValues() {
        homeHeaderTitle = homeHeaderTitleVar?.stringValue ?? "Today"
        homeHeaderSubtitle = homeHeaderSubtitleVar?.stringValue ?? "Discover something beautiful."
        featuredSectionTitle = featuredSectionTitleVar?.stringValue ?? "Featured"
        showFeaturedSection = showFeaturedSectionVar?.value as? Bool ?? true

        let configuredMax = maxFeaturedProductsVar?.numberValue?.intValue ?? 8
        maxFeaturedProducts = max(1, configuredMax)
    }

    func fetchVariables(completion: ((Bool) -> Void)? = nil) {
        CleverTap.sharedInstance()?.fetchVariables({ [weak self] success in
            Task { @MainActor in
                self?.hasFetchedVariables = success
                if success {
                    self?.applyCurrentValues()
                }
                completion?(success)
            }
        })
    }

    func syncVariablesInDebugBuild() {
        #if DEBUG
        CleverTap.sharedInstance()?.syncVariables()
        #endif
    }
}
