import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    var onFinish: (() -> Void)? = nil

    let pages: [OnboardingPage] = [
        OnboardingPage(
            imageAsset: "CleverTap logo",
            eyebrow: "IDENTITY + ANALYTICS",
            title: "Understand every user action",
            description: "Capture sign-up, login, catalog, and checkout behavior with robust profile and event tracking.",
            accent: Color(red: 0.20, green: 0.56, blue: 0.98),
            highlights: ["Profile Sync", "Realtime Events", "Lifecycle Signals"]
        ),
        OnboardingPage(
            imageAsset: "Clevertap1",
            eyebrow: "OMNICHANNEL MESSAGING",
            title: "Engage users at the right moment",
            description: "Run push, in-app, native display, and inbox campaigns from one journey orchestration workflow.",
            accent: Color(red: 0.06, green: 0.70, blue: 0.58),
            highlights: ["Push + In-App", "Native Display", "App Inbox Journeys"]
        ),
        OnboardingPage(
            imageAsset: "Clevertap2",
            eyebrow: "PRODUCT EXPERIENCES",
            title: "Personalize without app releases",
            description: "Use Product Experiences and remote variables to optimize content, offers, and UI dynamically.",
            accent: Color(red: 0.96, green: 0.46, blue: 0.32),
            highlights: ["Remote Variables", "Realtime Experimentation", "Journey Optimization"]
        )
    ]

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 16) {
                topBar

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageCard(page: page, colorScheme: colorScheme)
                            .tag(idx)
                            .padding(.horizontal, 4)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.42, dampingFraction: 0.86), value: currentPage)

                pageIndicator
                    .padding(.top, 2)

                bottomActions
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.02, green: 0.04, blue: 0.08), Color(red: 0.04, green: 0.07, blue: 0.14)]
                    : [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.90, green: 0.94, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.19, green: 0.56, blue: 0.98).opacity(colorScheme == .dark ? 0.30 : 0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 54)
                .offset(x: -100, y: -120)

            Circle()
                .fill(Color(red: 0.11, green: 0.72, blue: 0.58).opacity(colorScheme == .dark ? 0.24 : 0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 62)
                .offset(x: 160, y: 220)

            Circle()
                .fill(Color(red: 0.95, green: 0.48, blue: 0.34).opacity(colorScheme == .dark ? 0.20 : 0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: 140, y: -100)
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 10) {
                Image("CleverTap logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text("CleverTap Demo")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.primary)

            Spacer()

            Text("\(currentPage + 1)/\(pages.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())

            Button("Skip") {
                completeOnboarding()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(idx == currentPage ? pages[idx].accent : Color.primary.opacity(0.14))
                    .frame(width: idx == currentPage ? 30 : 10, height: 10)
                    .animation(.easeInOut(duration: 0.22), value: currentPage)
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            Button {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].accent.opacity(0.95), pages[currentPage].accent.opacity(0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .shadow(color: pages[currentPage].accent.opacity(0.34), radius: 14, x: 0, y: 8)
            }

            Text(currentPage == pages.count - 1 ? "Ready to start your CleverTap journey." : "Swipe left or tap continue.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        onFinish?()
    }
}

struct OnboardingPage {
    let imageAsset: String
    let eyebrow: String
    let title: String
    let description: String
    let accent: Color
    let highlights: [String]
}

private struct OnboardingPageCard: View {
    let page: OnboardingPage
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                page.accent.opacity(colorScheme == .dark ? 0.32 : 0.20),
                                page.accent.opacity(colorScheme == .dark ? 0.14 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.28), lineWidth: 1)
                    )

                Image(page.imageAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(26)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.45))
                            .padding(16)
                    )

                Text(page.eyebrow)
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(page.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(14)
            }
            .frame(height: 270)

            VStack(alignment: .leading, spacing: 12) {
                Text(page.title)
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(page.highlights, id: \.self) { feature in
                        HStack(spacing: 9) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(page.accent)
                            Text(feature)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.20 : 0.55), lineWidth: 1)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.32 : 0.12), radius: 22, x: 0, y: 12)
    }
}
