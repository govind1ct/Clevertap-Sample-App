import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainContent = false
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.white.ignoresSafeArea()
                
                if !showMainContent {
                    // CleverTap Logo
                    VStack {
                        CleverTapLogo(size: 50, animate: true)
                            .padding(.horizontal, 40)
                    }
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.8)) {
                            isAnimating = true
                        }
                        
                        // Transition to main content after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showMainContent = true
                            }
                        }
                    }
                } else {
                    if authViewModel.isAuthenticated {
                        MainTabView()
                            .environmentObject(authViewModel)
                            .transition(.opacity)
                    } else {
                        AuthLoginView()
                            .environmentObject(authViewModel)
                            .transition(.opacity)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
} 
