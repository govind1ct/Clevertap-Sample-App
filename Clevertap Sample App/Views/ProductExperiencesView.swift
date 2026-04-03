import SwiftUI
import UIKit
import CleverTapSDK

struct ProductExperiencesView: View {
    private enum ExperienceSection: Hashable {
        case testLab
        case appInbox
        case productExperiences
        case nativeDisplay
    }

    private enum ActiveSheet: Identifiable {
        case settings

        var id: String {
            switch self {
            case .settings:
                return "settings"
            }
        }
    }

    private enum ExperienceDestination: Identifiable {
        case testLabSelector
        case testLabDeveloper
        case testLabMarketer
        case appInbox
        case nativeDisplay

        var id: String {
            switch self {
            case .testLabSelector: return "testLabSelector"
            case .testLabDeveloper: return "testLabDeveloper"
            case .testLabMarketer: return "testLabMarketer"
            case .appInbox: return "appInbox"
            case .nativeDisplay: return "nativeDisplay"
            }
        }
    }

    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedSection: ExperienceSection = .testLab
    @State private var activeSheet: ActiveSheet?
    @State private var pushedDestination: ExperienceDestination?
    @State private var showStudioIntro = true
    @State private var animateContent = false
    @State private var animateAmbientBackground = false
    @State private var revealInteractiveCards = false
    @AppStorage("clevertap_lab_last_mode") private var lastTestLabMode = "developer"
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(
                    x: animateAmbientBackground ? -130 : -165,
                    y: animateAmbientBackground ? -335 : -365
                )

            Circle()
                .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 44)
                .offset(
                    x: animateAmbientBackground ? 150 : 180,
                    y: animateAmbientBackground ? -300 : -265
                )

            if showStudioIntro {
                ScrollView(showsIndicators: false) {
                    introScreen
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                }
                .scrollBounceBehavior(.basedOnSize)
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(spacing: 22) {
                        if selectedSection != .productExperiences {
                            headerSection
                            sectionSelector
                        }

                        sectionContent
                            .id(selectedSection)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                )
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 8)
                    .animation(.easeInOut(duration: 0.30), value: animateContent)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !showStudioIntro {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showStudioIntro = true
                        }
                    } label: {
                        Label("Overview", systemImage: "arrow.left.circle")
                    }
                }
            }
        }
        .onAppear {
            if !animateContent {
                animateContent = true
            }
            if !revealInteractiveCards {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.85).delay(0.10)) {
                    revealInteractiveCards = true
                }
            }
            if !animateAmbientBackground {
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    animateAmbientBackground = true
                }
            }
            if !productExperiencesService.isDemoModeLocked {
                productExperiencesService.fetchVariables()
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") { }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .settings:
                SettingsView()
            }
        }
        .navigationDestination(item: $pushedDestination) { destination in
            switch destination {
            case .testLabSelector:
                testLabSelectorPage
            case .testLabDeveloper:
                CleverTapTestViewV2()
            case .testLabMarketer:
                CleverTapTestView()
            case .appInbox:
                AppInboxView()
            case .nativeDisplay:
                NativeDisplayLabView()
            }
        }
    }
}

private extension ProductExperiencesView {
    var isDarkMode: Bool {
        colorScheme == .dark
    }

    var backgroundGradientColors: [Color] {
        if isDarkMode {
            return [
                Color(red: 0.04, green: 0.05, blue: 0.08),
                Color(red: 0.07, green: 0.09, blue: 0.14),
                Color("CleverTapPrimary").opacity(0.18),
                Color("CleverTapSecondary").opacity(0.10)
            ]
        }
        return [
            Color("CleverTapPrimary").opacity(0.20),
            Color("CleverTapSecondary").opacity(0.10),
            Color(.systemBackground),
            Color(.systemBackground)
        ]
    }

    var sectionBorderColor: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.24)
    }

    var rowBackgroundColor: Color {
        isDarkMode ? Color(red: 0.11, green: 0.13, blue: 0.18) : Color(.secondarySystemBackground).opacity(0.75)
    }

    var selectorBackgroundColor: Color {
        isDarkMode ? Color(red: 0.09, green: 0.10, blue: 0.15) : Color(.secondarySystemGroupedBackground)
    }

    var headerIconBackground: Color {
        isDarkMode ? Color(red: 0.14, green: 0.17, blue: 0.24) : Color.white.opacity(0.20)
    }

    var headerPillBackground: Color {
        isDarkMode ? Color("CleverTapPrimary").opacity(0.24) : Color("CleverTapPrimary").opacity(0.14)
    }

    var headerBadgeBackground: Color {
        isDarkMode ? Color(red: 0.13, green: 0.15, blue: 0.21) : rowBackgroundColor
    }

    var previewCanvasBase: Color {
        isDarkMode ? Color(red: 0.12, green: 0.14, blue: 0.20) : Color(.secondarySystemBackground)
    }

    var previewPanelFill: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color(.systemBackground).opacity(0.56)
    }

    var elevatedSurfaceFill: AnyShapeStyle {
        if isDarkMode {
            return AnyShapeStyle(Color(red: 0.08, green: 0.09, blue: 0.13).opacity(0.96))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    var heroPanelFill: AnyShapeStyle {
        if isDarkMode {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.09, green: 0.11, blue: 0.16),
                        Color(red: 0.07, green: 0.09, blue: 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    var useCompactControlsLayout: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    var introScreen: some View {
        VStack(alignment: .leading, spacing: 18) {
            workspaceLandingHeader
            testLabSpotlightCard
            workspaceCollection
        }
        .transition(.opacity)
    }

    private var usesSingleColumnLabHub: Bool {
        horizontalSizeClass == .compact || dynamicTypeSize >= .xLarge
    }

    var workspaceLandingHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLEVERTAP WORKSPACES")
                .font(.caption.weight(.bold))
                .foregroundColor(Color("CleverTapPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(headerPillBackground, in: Capsule())

            Text("Choose a workspace")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("Each workspace is focused on one job. Open the one that matches what you need to test or review.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var testLabSpotlightCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                workspaceGlyph(symbol: "brain.head.profile", accent: Color("CleverTapPrimary"))

                VStack(alignment: .leading, spacing: 8) {
                    workspaceTag("Primary")

                    Text("CleverTap Test Lab")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Run campaign QA, push flows, in-app checks, and inbox validation from one place.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                workspaceDetailStrip(
                    title: "Best For",
                    value: "Daily validation"
                )
                workspaceDetailStrip(
                    title: "Last Used",
                    value: lastTestLabMode == "demo" ? "Demo Workspace" : "Developer Console"
                )
            }

            if usesSingleColumnLabHub {
                VStack(spacing: 10) {
                    workspacePrimaryButton(title: preferredTestLabActionTitle, action: openPreferredTestLab)
                    workspaceSecondaryButton(title: "Choose Workspace") {
                        pushedDestination = .testLabSelector
                    }
                }
            } else {
                HStack(spacing: 10) {
                    workspacePrimaryButton(title: preferredTestLabActionTitle, action: openPreferredTestLab)
                    workspaceSecondaryButton(title: "Choose Workspace") {
                        pushedDestination = .testLabSelector
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(workspacePanelFill(accent: Color("CleverTapPrimary")))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
        .shadow(color: isDarkMode ? Color.black.opacity(0.22) : Color.clear, radius: 16, y: 8)
        .opacity(revealInteractiveCards ? 1 : 0)
        .offset(y: revealInteractiveCards ? 0 : 16)
        .animation(.spring(response: 0.56, dampingFraction: 0.86), value: revealInteractiveCards)
    }

    var workspaceCollection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More Workspaces")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)

            if usesSingleColumnLabHub {
                VStack(spacing: 12) {
                    workspaceTile(
                        title: "App Inbox",
                        subtitle: "Review messages and inbox rendering.",
                        icon: "tray.full.fill",
                        accent: Color("CleverTapSecondary"),
                        actionTitle: "Open Inbox"
                    ) {
                        pushedDestination = .appInbox
                    }

                    workspaceTile(
                        title: "Native Display",
                        subtitle: "Inspect placements and presentation surfaces.",
                        icon: "rectangle.3.group.fill",
                        accent: .orange,
                        actionTitle: "Open Native Display"
                    ) {
                        pushedDestination = .nativeDisplay
                    }

                    workspaceTile(
                        title: "Product Experiences",
                        subtitle: "Preview storefront looks and remote experience values.",
                        icon: "shippingbox.circle.fill",
                        accent: .green,
                        actionTitle: "Open Product Experiences"
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showStudioIntro = false
                            selectedSection = .productExperiences
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        workspaceTile(
                            title: "App Inbox",
                            subtitle: "Review messages and inbox rendering.",
                            icon: "tray.full.fill",
                            accent: Color("CleverTapSecondary"),
                            actionTitle: "Open Inbox"
                        ) {
                            pushedDestination = .appInbox
                        }

                        workspaceTile(
                            title: "Native Display",
                            subtitle: "Inspect placements and presentation surfaces.",
                            icon: "rectangle.3.group.fill",
                            accent: .orange,
                            actionTitle: "Open Native Display"
                        ) {
                            pushedDestination = .nativeDisplay
                        }
                    }

                    workspaceTile(
                        title: "Product Experiences",
                        subtitle: "Preview storefront looks and remote experience values.",
                        icon: "shippingbox.circle.fill",
                        accent: .green,
                        actionTitle: "Open Product Experiences"
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showStudioIntro = false
                            selectedSection = .productExperiences
                        }
                    }
                }
            }
        }
    }

    func workspaceGlyph(symbol: String, accent: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accent.opacity(isDarkMode ? 0.20 : 0.12))
                .frame(width: 68, height: 68)

            Image(systemName: symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(accent)
        }
    }

    func workspaceTag(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(rowBackgroundColor, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(sectionBorderColor, lineWidth: 1)
            )
    }

    func workspaceDetailStrip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(rowBackgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    func workspacePrimaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapPrimary").opacity(0.78)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    func workspaceSecondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(rowBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    func workspaceTile(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                workspaceGlyph(symbol: icon, accent: accent)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    Text(actionTitle)
                        .font(.footnote.weight(.bold))
                        .foregroundColor(accent)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.bold))
                        .foregroundColor(accent)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, minHeight: 196, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(workspacePanelFill(accent: accent))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(sectionBorderColor, lineWidth: 1)
            )
            .shadow(color: isDarkMode ? Color.black.opacity(0.18) : Color.clear, radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .opacity(revealInteractiveCards ? 1 : 0)
        .offset(y: revealInteractiveCards ? 0 : 16)
        .animation(.spring(response: 0.56, dampingFraction: 0.86), value: revealInteractiveCards)
    }

    func workspacePanelFill(accent: Color) -> some ShapeStyle {
        LinearGradient(
            colors: isDarkMode
                ? [
                    Color(.secondarySystemBackground),
                    accent.opacity(0.10),
                    Color(.tertiarySystemBackground)
                ]
                : [
                    Color.white,
                    accent.opacity(0.08),
                    Color(.systemGray6)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var preferredTestLabActionTitle: String {
        lastTestLabMode == "demo" ? "Open Demo Workspace" : "Open Developer Console"
    }

    private enum TestLabMode {
        case developer
        case demo
    }

    private func openPreferredTestLab() {
        openTestLab(lastTestLabMode == "demo" ? .demo : .developer)
    }

    private func openTestLab(_ mode: TestLabMode) {
        switch mode {
        case .developer:
            lastTestLabMode = "developer"
            pushedDestination = .testLabDeveloper
        case .demo:
            lastTestLabMode = "demo"
            pushedDestination = .testLabMarketer
        }
    }

    func testLabModeOption(
        title: String,
        subtitle: String,
        detail: String,
        icon: String,
        accent: Color,
        badge: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.18) : accent.opacity(isDarkMode ? 0.18 : 0.10))
                        .frame(width: 42, height: 42)

                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(isSelected ? .white : accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(isSelected ? .white : .primary)
                            Text(subtitle)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(isSelected ? .white.opacity(0.86) : accent)
                        }

                        Spacer(minLength: 0)

                        Text(badge.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundColor(isSelected ? .white : accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                isSelected ? Color.white.opacity(0.18) : accent.opacity(isDarkMode ? 0.20 : 0.12),
                                in: Capsule()
                            )
                    }

                    Text(detail)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.92) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [accent, accent.opacity(isDarkMode ? 0.86 : 0.78)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(accent.opacity(isDarkMode ? 0.14 : 0.08))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : accent.opacity(isDarkMode ? 0.30 : 0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var testLabSelectorPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("TEST LAB")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(headerPillBackground, in: Capsule())

                    Text("Choose the right workspace")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Developer Console is for diagnostics and QA. Demo Workspace is for presentation-friendly campaign walkthroughs.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(elevatedSurfaceFill, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )

                VStack(spacing: 12) {
                    testLabModeOption(
                        title: "Developer Console",
                        subtitle: "For developers, QA, and support teams",
                        detail: "Includes diagnostics, event validation, payload inspection, trigger tooling, and implementation checks.",
                        icon: "hammer.fill",
                        accent: Color("CleverTapPrimary"),
                        badge: lastTestLabMode == "developer" ? "Last Used" : "Recommended",
                        isSelected: lastTestLabMode == "developer"
                    ) {
                        openTestLab(.developer)
                    }

                    testLabModeOption(
                        title: "Demo Workspace",
                        subtitle: "For marketers, sales, and stakeholder walkthroughs",
                        detail: "Best for showcase flows, presentation-friendly demos, and explaining campaign behavior without debug-heavy controls.",
                        icon: "megaphone.fill",
                        accent: Color("CleverTapSecondary"),
                        badge: lastTestLabMode == "demo" ? "Last Used" : "Showcase",
                        isSelected: lastTestLabMode == "demo"
                    ) {
                        openTestLab(.demo)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle("Test Lab")
        .navigationBarTitleDisplayMode(.inline)
    }

    var headerSection: some View {
        Group {
            if selectedSection == .productExperiences {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRODUCT EXPERIENCES")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)

                            Text("Minimal Experience Lab")
                                .font(.system(size: 30, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("A cleaner Apple-style workspace for remote storefront values, presets, and fetch workflows.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 16)

                        VStack(alignment: .trailing, spacing: 10) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showStudioIntro = true
                                }
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.secondarySystemBackground), in: Circle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                activeSheet = .settings
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color(.secondarySystemBackground), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 10) {
                        quickBadge(
                            title: "Mode",
                            value: productExperiencesService.isDemoModeLocked ? "Demo Locked" : "Live"
                        )
                        quickBadge(
                            title: "Status",
                            value: productExperiencesService.hasFetchedVariables ? "Fetched" : "Idle"
                        )
                        quickBadge(
                            title: "Feature",
                            value: productExperiencesService.isFeatureEnabled ? "Enabled" : "Disabled"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REMOTE EXPERIENCE STUDIO")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("CleverTapPrimary"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(headerPillBackground, in: Capsule())

                            Text(headerTitle)
                                .font(.system(size: 31, weight: .heavy, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.70)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(headerSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 16)

                        Button {
                            activeSheet = .settings
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(headerIconBackground)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(Color("CleverTapPrimary"))
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        quickBadge(
                            title: "Mode",
                            value: productExperiencesService.isDemoModeLocked ? "Demo Locked" : "Live Fetch"
                        )
                        quickBadge(
                            title: "Status",
                            value: productExperiencesService.hasFetchedVariables ? "Fetched" : "Idle"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )
            }
        }
    }

    var sectionSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                selectorCard(
                    title: "CleverTap Test Lab",
                    subtitle: "Push, in-app, inbox tests",
                    icon: "brain.head.profile",
                    isSelected: selectedSection == .testLab
                ) {
                    selectSection(.testLab)
                }

                selectorCard(
                    title: "App Inbox",
                    subtitle: "User inbox messages",
                    icon: "tray.full.fill",
                    isSelected: selectedSection == .appInbox
                ) {
                    selectSection(.appInbox)
                }

                selectorCard(
                    title: "Product Experiences",
                    subtitle: "Remote config variables",
                    icon: "shippingbox.fill",
                    isSelected: selectedSection == .productExperiences
                ) {
                    selectSection(.productExperiences)
                }

                selectorCard(
                    title: "Native Display",
                    subtitle: "Display units and locations",
                    icon: "rectangle.3.group.fill",
                    isSelected: selectedSection == .nativeDisplay
                ) {
                    selectSection(.nativeDisplay)
                }
            }

            if selectedSection == .productExperiences {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color("CleverTapPrimary"))
                    Text("Product Experiences Active")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )
            } else {
                Button {
                    openFromStudioSelection()
                } label: {
                    HStack(spacing: 8) {
                        Text(studioCtaTitle)
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }

            if selectedSection == .productExperiences {
                Toggle("Enable Product Experiences", isOn: Binding(
                    get: { productExperiencesService.isFeatureEnabled },
                    set: { productExperiencesService.setFeatureEnabled($0) }
                ))
                .toggleStyle(.switch)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(sectionBorderColor, lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedSection)
    }

    private func selectSection(_ section: ExperienceSection) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            selectedSection = section
        }
    }

    func selectorCard(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 42, height: 42)
                    .background(
                        (isSelected ? Color("CleverTapPrimary") : Color(.secondarySystemBackground)),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color("CleverTapPrimary") : sectionBorderColor, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    var sectionContent: some View {
        switch selectedSection {
        case .testLab:
            testLabSection
        case .appInbox:
            appInboxSection
        case .productExperiences:
            productExperiencesSection
        case .nativeDisplay:
            nativeDisplaySection
        }
    }

    var productExperiencesSection: some View {
        VStack(spacing: 18) {
            experiencePreviewStage
            if !productExperiencesService.isFeatureEnabled {
                disabledBanner
            }
            experienceControlsPanel
            experienceLooksPanel
            experienceSummaryPanel
        }
    }

    var disabledBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Product Experiences Disabled")
                    .font(.subheadline.weight(.semibold))
                Text("Home uses app defaults only. Remote dashboard values are ignored.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.orange.opacity(0.25), lineWidth: 1)
        )
    }

    var experiencePreviewStage: some View {
        VStack(alignment: .leading, spacing: 18) {
            productExperienceSectionHeader(
                "Experience Preview",
                subtitle: "A live storefront read of the current remote experience."
            )

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(previewCanvasBase)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color(hex: productExperiencesService.homeThemeGradientStart).opacity(isDarkMode ? (productExperiencesService.isFeatureEnabled ? 0.42 : 0.18) : (productExperiencesService.isFeatureEnabled ? 0.30 : 0.12)),
                                Color(hex: productExperiencesService.homeThemeGradientEnd).opacity(isDarkMode ? (productExperiencesService.isFeatureEnabled ? 0.28 : 0.14) : (productExperiencesService.isFeatureEnabled ? 0.16 : 0.08))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: isDarkMode ? .black.opacity(0.26) : .clear, radius: 18, y: 10)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            if productExperiencesService.showHomeHeaderBadge && !productExperiencesService.homeHeaderBadge.isEmpty {
                                Text(productExperiencesService.homeHeaderBadge.uppercased())
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(isDarkMode ? .white.opacity(0.82) : .secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isDarkMode ? Color.white.opacity(0.10) : Color(.systemBackground).opacity(0.75), in: Capsule())
                            }

                            Text(productExperiencesService.homeHeaderTitle)
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .lineLimit(2)

                            Text(productExperiencesService.homeHeaderSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }

                        Spacer(minLength: 14)
                    }

                    VStack(spacing: 12) {
                        HStack {
                            Text(productExperiencesService.featuredSectionTitle)
                                .font(.headline.weight(.semibold))
                            Spacer()
                            Text(productExperiencesService.showFeaturedSection ? "\(productExperiencesService.maxFeaturedProducts) items" : "Hidden")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(isDarkMode ? Color.white.opacity(0.12) : Color(.systemBackground).opacity(0.72))
                                        .frame(height: 92)
                                        .overlay(
                                            Image(systemName: index == 0 ? "sparkles" : index == 1 ? "circle.grid.2x2.fill" : "bag.fill")
                                                .font(.title3.weight(.semibold))
                                                .foregroundColor(isDarkMode ? .white.opacity(0.68) : .secondary.opacity(0.85))
                                        )

                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isDarkMode ? Color.white.opacity(0.18) : Color(.systemBackground).opacity(0.82))
                                        .frame(height: 10)

                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isDarkMode ? Color.white.opacity(0.10) : Color(.systemBackground).opacity(0.62))
                                        .frame(width: index == 1 ? 54 : 70, height: 10)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(16)
                    .background(previewPanelFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04), lineWidth: 1)
                    )
                }
                .padding(22)
                .opacity(productExperiencesService.isFeatureEnabled ? 1 : 0.68)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(elevatedSurfaceFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var experienceControlsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            productExperienceSectionHeader(
                "Controls",
                subtitle: "Feature state, demo lock, and sync actions."
            )

            experienceMinimalToggleRow(
                title: "Product Experiences",
                subtitle: "Use remote values across the storefront",
                isOn: Binding(
                    get: { productExperiencesService.isFeatureEnabled },
                    set: { productExperiencesService.setFeatureEnabled($0) }
                )
            )

            experienceMinimalToggleRow(
                title: "Demo Lock",
                subtitle: "Keep the preview fixed for walkthroughs",
                isOn: Binding(
                    get: { productExperiencesService.isDemoModeLocked },
                    set: { productExperiencesService.setDemoModeLocked($0) }
                )
            )

            if useCompactControlsLayout {
                VStack(spacing: 10) {
                    fetchButton
                    syncButton
                }
            } else {
                HStack(spacing: 12) {
                    fetchButton
                    syncButton
                }
            }

            Text(productExperiencesService.isDemoModeLocked
                 ? "Demo Lock is on. Turn it off to fetch fresh dashboard values."
                 : "Fetch pulls the latest remote values. Sync runs a debug refresh and fetches again.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(elevatedSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var experienceLooksPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            productExperienceSectionHeader(
                "Looks",
                subtitle: "Pick the presentation style for the active demo."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    lookCard(
                        title: "Luxury",
                        subtitle: "Warm metals, premium energy",
                        footnote: "Best for premium demos",
                        colors: [Color(hex: "#C9A45C"), Color(hex: "#F5E7C8")],
                        isActive: themeManager.isLuxuryActive && productExperiencesService.isDemoModeLocked
                    ) {
                        productExperiencesService.applyDemoPreset(.luxuryLaunch)
                        CleverTap.sharedInstance()?.recordEvent(
                            "luxury_preset_selected",
                            withProps: ["source": "Product Experiences"]
                        )
                        themeManager.setLuxuryActive(true)
                        alertMessage = "Applied preset: Luxury Launch."
                        showAlert = true
                    }

                    lookCard(
                        title: "Festive",
                        subtitle: "Brighter contrast and urgency",
                        footnote: "Best for campaign walkthroughs",
                        colors: [Color(hex: "#FF8C5A"), Color(hex: "#FFD166")],
                        isActive: !themeManager.isLuxuryActive && productExperiencesService.isDemoModeLocked
                    ) {
                        productExperiencesService.applyDemoPreset(.festiveSale)
                        themeManager.setLuxuryActive(false)
                        alertMessage = "Applied preset: Festive Sale."
                        showAlert = true
                    }

                    lookCard(
                        title: "Default",
                        subtitle: "App baseline without demo styling",
                        footnote: "Best for showing the natural state",
                        colors: [Color(.systemGray4), Color(.systemGray6)],
                        isActive: !themeManager.isLuxuryActive && !productExperiencesService.isDemoModeLocked
                    ) {
                        productExperiencesService.applyDemoPreset(.reset)
                        themeManager.setLuxuryActive(false)
                        alertMessage = "Reset to app defaults."
                        showAlert = true
                    }
                }
            }
        }
        .padding(20)
        .background(elevatedSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var experienceSummaryPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            productExperienceSectionHeader(
                "Live Setup",
                subtitle: "The three values currently shaping the storefront.",
                badge: productExperiencesService.hasFetchedVariables ? "Fetched" : "Idle"
            )

            VStack(spacing: 0) {
                productExperienceValueRow(
                    label: "Header",
                    value: productExperiencesService.homeHeaderBadge.isEmpty
                        ? productExperiencesService.homeHeaderTitle
                        : "\(productExperiencesService.homeHeaderTitle) • \(productExperiencesService.homeHeaderBadge)"
                )
                Divider()
                productExperienceValueRow(
                    label: "Featured",
                    value: productExperiencesService.showFeaturedSection
                        ? "\(productExperiencesService.featuredSectionTitle) • \(productExperiencesService.maxFeaturedProducts) items"
                        : "\(productExperiencesService.featuredSectionTitle) • Hidden"
                )
                Divider()
                productExperienceValueRow(
                    label: "Theme",
                    value: "\(productExperiencesService.homeThemeGradientStart) → \(productExperiencesService.homeThemeGradientEnd)"
                )
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(20)
        .background(elevatedSurfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var experienceActionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actions")
                .font(.title3.weight(.semibold))

            if useCompactControlsLayout {
                VStack(spacing: 10) {
                    fetchButton
                    syncButton
                }
            } else {
                HStack(spacing: 12) {
                    fetchButton
                    syncButton
                }
            }

            Text(productExperiencesService.isDemoModeLocked
                 ? "Turn off Demo Lock to fetch remote dashboard values."
                 : "Fetch pulls the latest dashboard values. Sync runs a debug refresh and then fetches again.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var testLabSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CleverTap Test Lab")
                .font(.headline)

            Text("Use the Test Lab to validate push, in-app templates, app inbox, and native display behavior.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink {
                CleverTapTestViewV2()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open CleverTap Test Lab")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Run full test workflows")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.92))
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: Color("CleverTapPrimary").opacity(0.32), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var appInboxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("App Inbox")
                .font(.headline)

            Text("Open CleverTap App Inbox to view rich messages delivered to the user profile.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink {
                AppInboxView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "tray.full.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open App Inbox")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Review inbox campaigns")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.92))
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: Color("CleverTapPrimary").opacity(0.32), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    var nativeDisplaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Native Display")
                .font(.headline)

            Text("Review display placements, trigger location events, and inspect payload rendering in a dedicated workspace.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                pushedDestination = .nativeDisplay
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open Native Display Workspace")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("View units, triggers, and debug data")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.92))
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: Color("CleverTapPrimary").opacity(0.32), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    func experienceMinimalToggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func productExperienceSectionHeader(
        _ title: String,
        subtitle: String,
        badge: String? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let badge {
                Text(badge.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Color("CleverTapPrimary"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color("CleverTapPrimary").opacity(isDarkMode ? 0.18 : 0.10), in: Capsule())
            }
        }
    }

    func lookCard(
        title: String,
        subtitle: String,
        footnote: String,
        colors: [Color],
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(isActive ? "SELECTED" : "LOOK")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isActive ? .primary : .secondary)
                    Spacer()
                    Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isActive ? Color("CleverTapPrimary") : .secondary.opacity(0.7))
                }

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 114)
                    .overlay(
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(index == 1 ? 0.60 : 0.34))
                                    .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 74)
                            }
                        }
                        .padding(14)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(footnote)
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.9))
                }
            }
            .padding(16)
            .frame(width: 252, alignment: .leading)
            .background(
                (isActive ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground)),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isActive ? Color("CleverTapPrimary").opacity(0.55) : sectionBorderColor, lineWidth: isActive ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    func productExperienceValueRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    var storefrontPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Storefront Preview")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color("CleverTapPrimary"))
                    Text("A quick read of the current storefront experience.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if productExperiencesService.showHomeHeaderBadge && !productExperiencesService.homeHeaderBadge.isEmpty {
                    Text(productExperiencesService.homeHeaderBadge)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(productExperiencesService.homeHeaderTitle)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(productExperiencesService.homeHeaderSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Section")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    Text(productExperiencesService.featuredSectionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(productExperiencesService.showFeaturedSection ? "\(productExperiencesService.maxFeaturedProducts) products visible" : "Currently hidden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: productExperiencesService.homeThemeGradientStart),
                                Color(hex: productExperiencesService.homeThemeGradientEnd)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white.opacity(0.9))
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackgroundColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(sectionBorderColor, lineWidth: 1)
        )
    }

    func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(rowBackgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func actionLabel(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    func prominentActionLabel(title: String, icon: String, gradient: [Color]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(
            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: gradient.first?.opacity(0.32) ?? .clear, radius: 10, y: 7)
    }

    var fetchButton: some View {
        Button {
            guard !productExperiencesService.isDemoModeLocked else {
                alertMessage = "Demo Mode Lock is ON. Disable it to fetch dashboard values."
                showAlert = true
                return
            }
            productExperiencesService.fetchVariables { success in
                alertMessage = success ? "Variables fetched successfully." : "Failed to fetch variables."
                showAlert = true
            }
        } label: {
            prominentActionLabel(
                title: "Fetch",
                icon: "arrow.clockwise",
                gradient: [Color("CleverTapPrimary"), Color("CleverTapSecondary")]
            )
        }
        .disabled(!productExperiencesService.isFeatureEnabled)
    }

    var syncButton: some View {
        Button {
            guard !productExperiencesService.isDemoModeLocked else {
                alertMessage = "Demo Mode Lock is ON. Disable it to sync/fetch dashboard values."
                showAlert = true
                return
            }
            productExperiencesService.syncVariablesInDebugBuild()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                productExperiencesService.fetchVariables { success in
                    alertMessage = success ? "Sync + fetch completed." : "Sync triggered, fetch failed."
                    showAlert = true
                }
            }
        } label: {
            prominentActionLabel(
                title: "Sync (Debug)",
                icon: "hammer",
                gradient: [Color.indigo, Color.blue]
            )
        }
        .disabled(!productExperiencesService.isFeatureEnabled)
    }

    private func openFromStudioSelection() {
        switch selectedSection {
        case .testLab:
            openPreferredTestLab()
        case .appInbox:
            pushedDestination = .appInbox
        case .nativeDisplay:
            pushedDestination = .nativeDisplay
        case .productExperiences:
            break
        }
    }

    private var studioCtaTitle: String {
        switch selectedSection {
        case .testLab:
            return "Open CleverTap Test Lab"
        case .appInbox:
            return "Open App Inbox"
        case .productExperiences:
            return "Product Experiences Active"
        case .nativeDisplay:
            return "Open Native Display"
        }
    }

    private var headerTitle: String {
        switch selectedSection {
        case .testLab:
            return "CleverTap Test Lab"
        case .appInbox:
            return "App Inbox"
        case .productExperiences:
            return "Product Experiences"
        case .nativeDisplay:
            return "Native Display"
        }
    }

    private var headerSubtitle: String {
        switch selectedSection {
        case .testLab:
            return "Validate push, in-app, inbox, and engagement journeys in one place."
        case .appInbox:
            return "Review user-targeted rich inbox campaigns and message rendering."
        case .productExperiences:
            return "Control Home UI in real time with polished demo controls and production-safe fetch flows."
        case .nativeDisplay:
            return "Audit native display units, payloads, and placement behavior."
        }
    }

    func quickBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(headerBadgeBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ProductExperiencesView()
    }
}
