import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        Group {
            if auth.isAuthenticated {
                // Replace with your actual main app entry view if different
                CleverTapProfileDashboardView()
            } else {
                AuthLoginView()
            }
        }
    }
}

#Preview {
    // For preview, provide a temporary AuthViewModel
    let vm = AuthViewModel()
    vm.isAuthenticated = false
    return RootView().environmentObject(vm)
}
