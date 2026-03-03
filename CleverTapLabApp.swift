import SwiftUI
import CleverTapSDK

@main
struct CleverTapLabApp: App {
    @StateObject private var authManager = AuthManager()
    
    init() {
        // Initialize CleverTap
        CleverTap.autoIntegrate()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                CleverTapTestingLabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
} 