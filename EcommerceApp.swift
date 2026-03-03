import SwiftUI
import CleverTapSDK

@main
struct EcommerceApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var cartManager = CartManager()
    
    init() {
        // Initialize CleverTap
        CleverTap.autoIntegrate()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(cartManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
} 