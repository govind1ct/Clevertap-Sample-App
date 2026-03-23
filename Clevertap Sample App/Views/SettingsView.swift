import SwiftUI

struct SettingsView: View {
    @AppStorage("hasSeenMainTabWalkthrough") private var hasSeenMainTabWalkthrough: Bool = false
    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @State private var showReplayConfirmation = false
    @Environment(\.colorScheme) private var colorScheme

    private let releaseHighlights = [
        "Refreshed Experiences and Test Lab UI with clearer flows.",
        "Improved dark mode readability and adaptive text rendering.",
        "Profile and auth flow reliability updates for better user sync.",
        "CleverTap integration polish across onboarding and profile surfaces."
    ]

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var surfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.82)
    }

    private var secondarySurfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.035)
    }

    private var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.07)
    }

    private var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.88)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.72) : Color.black.opacity(0.6)
    }

    private var backgroundGradientColors: [Color] {
        if isDarkMode {
            return [
                Color(red: 0.08, green: 0.09, blue: 0.14),
                Color("CleverTapPrimary").opacity(0.20),
                Color(red: 0.05, green: 0.06, blue: 0.10),
                Color.black
            ]
        }
        return [
            Color("CleverTapPrimary").opacity(0.12),
            Color("CleverTapSecondary").opacity(0.08),
            Color.white,
            Color(.systemGroupedBackground)
        ]
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: backgroundGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 36)
                    .offset(x: -140, y: -320)

                Circle()
                    .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.10))
                    .frame(width: 300, height: 300)
                    .blur(radius: 48)
                    .offset(x: 160, y: -260)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        headerSection
                        generalSection
                        walkthroughSection
                        releaseSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Walkthrough reset. Open main tabs to view nudges again.", isPresented: $showReplayConfirmation) {
                Button("OK", role: .cancel) { }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SETTINGS")
                .font(.caption.weight(.bold))
                .foregroundColor(Color("CleverTapPrimary"))
                .tracking(1.2)

            Text("App Settings")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(primaryText)

            Text("Manage demo behavior, walkthrough controls, and release information in one place.")
                .font(.subheadline)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(surfaceFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.22 : 0.08), radius: 18, y: 8)
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("General", subtitle: "Control Product Experiences behavior.")

            Toggle("Enable Product Experiences", isOn: Binding(
                get: { productExperiencesService.isFeatureEnabled },
                set: { productExperiencesService.setFeatureEnabled($0) }
            ))
            .foregroundColor(primaryText)
            .padding(14)
            .background(secondarySurfaceFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 10) {
                Image(systemName: productExperiencesService.isFeatureEnabled ? "checkmark.seal.fill" : "pause.circle.fill")
                    .foregroundColor(productExperiencesService.isFeatureEnabled ? .green : .orange)
                Text(productExperiencesService.isFeatureEnabled
                     ? "Remote variables can be fetched and applied."
                     : "Product Experiences are disabled and app defaults are used.")
                .font(.caption)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        }
        .settingsCardStyle(isDarkMode: isDarkMode)
    }

    private var walkthroughSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Guided Walkthrough", subtitle: "Replay first-time tab nudges.")

            Button {
                hasSeenMainTabWalkthrough = false
                NotificationCenter.default.post(name: .replayMainTabWalkthrough, object: nil)
                showReplayConfirmation = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Replay App Walkthrough")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 14)
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

            Text("Shows first-time tab nudges again for Home, Experiences, Cart, and Profile.")
                .font(.caption)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .settingsCardStyle(isDarkMode: isDarkMode)
    }

    private var releaseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("About This Release", subtitle: "Current app build and latest improvements.")

            HStack {
                Text("App Version")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryText)
                Spacer()
                Text(appVersionDisplay)
                    .font(.subheadline)
                    .foregroundColor(secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(secondarySurfaceFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("What's New in 3.0")
                .font(.headline)
                .foregroundColor(primaryText)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(releaseHighlights, id: \.self) { highlight in
                    Label {
                        Text(highlight)
                            .font(.subheadline)
                            .foregroundColor(primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color("CleverTapPrimary"))
                    }
                }
            }
        }
        .settingsCardStyle(isDarkMode: isDarkMode)
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(primaryText)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appVersionDisplay: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version) (\(build))"
    }
}

private extension View {
    func settingsCardStyle(isDarkMode: Bool) -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.82),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isDarkMode ? Color.white.opacity(0.12) : Color.black.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isDarkMode ? 0.18 : 0.06), radius: 14, y: 6)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
