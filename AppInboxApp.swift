import SwiftUI
import CleverTapSDK

@main
struct AppInboxApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var inAppService = CleverTapInAppService.shared
    
    init() {
        // Initialize CleverTap
        CleverTap.autoIntegrate()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                AppInboxView()
                    .environmentObject(authManager)
                    .environmentObject(inAppService)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
} 