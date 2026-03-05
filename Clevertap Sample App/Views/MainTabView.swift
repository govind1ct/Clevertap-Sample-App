import SwiftUI
import UIKit

struct MainTabView: View {
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cartManager: CartManager
    @StateObject private var inAppService = CleverTapInAppService.shared
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    
    enum Tab: Int {
        case home, inbox, experiences, cart, profile
    }
    
    @State private var selectedTab: Tab = .home
    @AppStorage("hasSeenMainTabWalkthrough") private var hasSeenMainTabWalkthrough: Bool = false
    @State private var showWalkthroughNudges = false
    @State private var walkthroughStepIndex = 0

    private struct WalkthroughStep {
        let tab: Tab
        let title: String
        let message: String
        let icon: String
    }

    private var walkthroughSteps: [WalkthroughStep] {
        [
            WalkthroughStep(
                tab: .home,
                title: "Home",
                message: "Browse products, search quickly, and discover featured recommendations.",
                icon: "house.fill"
            ),
            WalkthroughStep(
                tab: .experiences,
                title: "Experiences",
                message: "Fetch Product Experiences and preview remote UI updates in real time.",
                icon: "wand.and.stars"
            ),
            WalkthroughStep(
                tab: .cart,
                title: "Cart",
                message: "Review selected products and continue to checkout when ready.",
                icon: "cart.fill"
            ),
            WalkthroughStep(
                tab: .profile,
                title: "Profile",
                message: "Manage profile data, sync to CleverTap, and monitor dashboard metrics.",
                icon: "person.crop.circle.fill"
            )
        ]
    }
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            
            // MARK: - Home
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label {
                    Text("Home")
                } icon: {
                    Image(systemName: selectedTab == .home ? "house.fill" : "house")
                }
            }
            .tag(Tab.home)
            
            
            // MARK: - Inbox
            NavigationStack {
                AppInboxView()
            }
            .tabItem {
                Label {
                    Text("Inbox")
                } icon: {
                    Image(systemName: selectedTab == .inbox ? "tray.fill" : "tray")
                }
            }
            .tag(Tab.inbox)
            
            
            // MARK: - Product Experiences
            NavigationStack {
                ProductExperiencesView()
            }
            .tabItem {
                Label {
                    Text("Experiences")
                } icon: {
                    Image(systemName: selectedTab == .experiences ? "wand.and.stars.inverse" : "wand.and.stars")
                }
            }
            .tag(Tab.experiences)
            
            
            // MARK: - Cart
            NavigationStack {
                CartView()
            }
            .tabItem {
                Label {
                    Text("Cart")
                } icon: {
                    Image(systemName: selectedTab == .cart ? "cart.fill" : "cart")
                }
            }
            .badge(cartManager.items.count > 0 ? cartManager.items.count : 0)
            .tag(Tab.cart)
            
            
            // MARK: - Profile
            NavigationStack {
                Group {
                    if authViewModel.isAuthenticated {
                        ProfileView()
                    } else {
                        AuthLoginView()
                    }
                }
            }
            .tabItem {
                Label {
                    Text("Profile")
                } icon: {
                    Image(systemName: selectedTab == .profile ? "person.crop.circle.fill" : "person.crop.circle")
                }
            }
            .tag(Tab.profile)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .tint(Color("CleverTapPrimary"))
        .overlay(alignment: .bottom) {
            if showWalkthroughNudges {
                walkthroughNudgeCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            configureTabBarAppearance()
            startWalkthroughIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .replayMainTabWalkthrough)) { _ in
            restartWalkthrough()
        }
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            if selectedTab == .home || selectedTab == .profile {
                CleverTapNativeDisplayService.shared.refreshDisplayUnits()
            }
        }
    }
}


// MARK: - Apple Minimalist Tab Bar Styling

private extension MainTabView {
    var walkthroughNudgeCard: some View {
        let step = walkthroughSteps[walkthroughStepIndex]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: step.icon)
                    .font(.headline)
                    .foregroundStyle(Color("CleverTapPrimary"))
                    .frame(width: 34, height: 34)
                    .background(Color("CleverTapPrimary").opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("First-time walkthrough")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(step.title)
                        .font(.headline)
                    Text(step.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text("\(walkthroughStepIndex + 1)/\(walkthroughSteps.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button("Skip") {
                    finishWalkthrough()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer()

                Button(walkthroughStepIndex == walkthroughSteps.count - 1 ? "Got it" : "Next") {
                    advanceWalkthrough()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("CleverTapPrimary"), in: Capsule())
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    func startWalkthroughIfNeeded() {
        guard !hasSeenMainTabWalkthrough, !showWalkthroughNudges else { return }
        walkthroughStepIndex = 0
        selectedTab = walkthroughSteps[0].tab
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showWalkthroughNudges = true
        }
    }

    func advanceWalkthrough() {
        if walkthroughStepIndex < walkthroughSteps.count - 1 {
            walkthroughStepIndex += 1
            selectedTab = walkthroughSteps[walkthroughStepIndex].tab
        } else {
            finishWalkthrough()
        }
    }

    func finishWalkthrough() {
        withAnimation(.easeOut(duration: 0.2)) {
            showWalkthroughNudges = false
        }
        hasSeenMainTabWalkthrough = true
    }

    func restartWalkthrough() {
        hasSeenMainTabWalkthrough = false
        walkthroughStepIndex = 0
        selectedTab = walkthroughSteps[0].tab
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showWalkthroughNudges = true
        }
    }
    
    func configureTabBarAppearance() {
        
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.58)
        
        // Selected
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color("CleverTapPrimary"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color("CleverTapPrimary")),
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ]
        appearance.stackedLayoutAppearance.selected.badgeBackgroundColor = UIColor(Color("CleverTapPrimary"))
        
        // Normal
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor.systemRed
        
        // Subtle selected indicator for a premium tab focus state
        let indicatorSize = CGSize(width: 66, height: 30)
        appearance.selectionIndicatorImage = tabSelectionIndicator(
            color: UIColor(Color("CleverTapPrimary")).withAlphaComponent(0.16),
            size: indicatorSize
        )
        
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
        appearance.shadowImage = UIImage()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().itemWidth = 72
        UITabBar.appearance().itemPositioning = .centered
        UITabBar.appearance().itemSpacing = 8
    }
    
    func tabSelectionIndicator(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 14)
            color.setFill()
            path.fill()
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            context.cgContext.setLineWidth(1)
            path.stroke()
        }
        .resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
    }
}


extension Notification.Name {
    static let replayMainTabWalkthrough = Notification.Name("replayMainTabWalkthrough")
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(CartManager())
}
