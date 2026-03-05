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
    @State private var showSplash = true
    
    // Use AppDelegate for push notifications and CleverTap setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.25)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    if authViewModel.isAuthenticated {
                        MainTabView()
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    } else if showGuestOnboarding {
                        OnboardingView {
                            withAnimation(.spring(response: 0.50, dampingFraction: 0.88)) {
                                showGuestOnboarding = false
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        AuthLoginView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.40), value: showSplash)
            .animation(.spring(response: 0.50, dampingFraction: 0.88), value: showGuestOnboarding)
            .animation(.easeInOut(duration: 0.35), value: authViewModel.isAuthenticated)
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
