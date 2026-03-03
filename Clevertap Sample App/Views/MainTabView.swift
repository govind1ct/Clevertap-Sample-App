import SwiftUI
import UIKit

struct MainTabView: View {
    
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cartManager: CartManager
    @StateObject private var inAppService = CleverTapInAppService.shared
    
    enum Tab: Int {
        case home, inbox, experiences, cart, profile
    }
    
    @State private var selectedTab: Tab = .home
    
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
                    Image(systemName: "house")
                        .symbolVariant(selectedTab == .home ? .fill : .none)
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
                    Image(systemName: "tray")
                        .symbolVariant(selectedTab == .inbox ? .fill : .none)
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
                    Image(systemName: "sparkles")
                        .symbolVariant(selectedTab == .experiences ? .fill : .none)
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
                    Image(systemName: "cart")
                        .symbolVariant(selectedTab == .cart ? .fill : .none)
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
                    Image(systemName: "person.crop.circle")
                        .symbolVariant(selectedTab == .profile ? .fill : .none)
                }
            }
            .tag(Tab.profile)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .tint(Color("CleverTapPrimary"))
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: selectedTab) { _, _ in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}


// MARK: - Apple Minimalist Tab Bar Styling

private extension MainTabView {
    
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


#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(CartManager())
}
