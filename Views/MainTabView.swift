import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.05),
                    Color("CleverTapSecondary").opacity(0.02),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                NavigationView {
                    HomeView()
                }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 20, weight: .medium))
                    Text("Home")
                        .font(.caption.weight(.medium))
                }
                .tag(0)
                
                NavigationView {
                    AppInboxView()
                }
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "tray.fill" : "tray")
                        .font(.system(size: 20, weight: .medium))
                    Text("Inbox")
                        .font(.caption.weight(.medium))
                }
                .tag(1)
                
                NavigationView {
                    CleverTapTestingLabView()
                }
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "testtube.2.fill" : "testtube.2")
                        .font(.system(size: 20, weight: .medium))
                    Text("Test Lab")
                        .font(.caption.weight(.medium))
                }
                .tag(2)
            }
            .accentColor(Color("CleverTapPrimary"))
            .onAppear {
                setupTabBarAppearance()
            }
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Tab bar background with blur effect
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        // Selected tab item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color("CleverTapPrimary"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color("CleverTapPrimary")),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Normal tab item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
} 