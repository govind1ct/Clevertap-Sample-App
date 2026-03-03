import SwiftUI
import FirebaseCore
import CleverTapSDK
import UserNotifications

@main
struct Clevertap_Sample_AppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var cartManager = CartManager()
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showGuestOnboarding = true
    
    // Use AppDelegate for push notifications and CleverTap setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else if showGuestOnboarding {
                    OnboardingView {
                        showGuestOnboarding = false
                    }
                } else {
                    AuthLoginView()
                }
            }
            .environmentObject(authViewModel)
            .environmentObject(cartManager)
            .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
                if !isAuthenticated {
                    showGuestOnboarding = true
                }
            }
            .onAppear {
                // Verify CleverTap delegate setup
                print("✅ App Started - CleverTap delegate should be set in AppDelegate")
                
                // Print debug info
                if let cleverTapID = CleverTap.sharedInstance()?.profileGetID() {
                    print("🔧 CleverTap Profile ID: \(cleverTapID)")
                }
                
                productExperiencesService.fetchVariables()
                productExperiencesService.syncVariablesInDebugBuild()
            }
        }
    }
}
