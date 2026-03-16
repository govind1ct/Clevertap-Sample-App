import Foundation
import FirebaseAuth
import FirebaseCore
import CleverTapSDK
import UIKit

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isAdmin: Bool = false

    private let adminEmail = "govind.pathak@clevertap.com"
    
    init() {
        self.user = Auth.auth().currentUser
        self.isAuthenticated = self.user != nil
        refreshAdminStatus()
    }
    
    func signIn(email: String, password: String) {
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            if let user = result?.user {
                self?.isAuthenticated = true
                self?.user = user
                
                // CleverTap User Profile Update on Login
                CleverTapService.shared.createUserProfile(
                    email: email,
                    userId: user.uid,
                    name: user.displayName ?? "",
                    isNewUser: false
                )

                self?.refreshAdminStatus()
                
                // Track login event
                CleverTap.sharedInstance()?.recordEvent("User Logged In", withProps: [
                    "Login Method": "Email",
                    "User ID": user.uid
                ])
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        errorMessage = nil
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            if let user = result?.user {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges { error in
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    self?.isAuthenticated = true
                    self?.user = user
                    self?.refreshAdminStatus()
                    
                    // CleverTap User Profile Creation on Signup
                    CleverTapService.shared.createUserProfile(
                        email: email,
                        userId: user.uid,
                        name: name,
                        isNewUser: true
                    )
                    
                    // Track signup event
                    CleverTap.sharedInstance()?.recordEvent("User Signed Up", withProps: [
                        "Signup Method": "Email",
                        "User ID": user.uid,
                        "Name": name
                    ])
                }
            }
        }
    }

    func signInWithGoogle(source: String = "unknown") {
        errorMessage = nil
        
        CleverTap.sharedInstance()?.recordEvent("Google Auth Clicked", withProps: [
            "Source": source
        ])

        #if canImport(GoogleSignIn)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Firebase client ID."
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let presentingVC = Self.topViewController() else {
            errorMessage = "Unable to open Google Sign-In."
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                CleverTap.sharedInstance()?.recordEvent("Google Auth Failed", withProps: [
                    "Source": source
                ])
                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self?.errorMessage = "Google Sign-In failed. Try again."
                return
            }

            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, authError in
                if let authError = authError {
                    self?.errorMessage = authError.localizedDescription
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self?.errorMessage = "Unable to authenticate with Firebase."
                    return
                }

                self?.isAuthenticated = true
                self?.user = firebaseUser
                self?.refreshAdminStatus()

                let email = firebaseUser.email ?? ""
                let name = firebaseUser.displayName ?? "User"

                CleverTapService.shared.createUserProfile(
                    email: email,
                    userId: firebaseUser.uid,
                    name: name,
                    isNewUser: false
                )

                CleverTap.sharedInstance()?.recordEvent("User Logged In", withProps: [
                    "Login Method": "Google",
                    "User ID": firebaseUser.uid,
                    "Source": source
                ])
            }
        }
        #else
        errorMessage = "Google Sign-In SDK not added. Add package: google/GoogleSignIn-iOS."
        #endif
    }
    
    func signOut() {
        do {
            let previousUserID = user?.uid
            try Auth.auth().signOut()
            isAuthenticated = false
            user = nil
            isAdmin = false
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
            CleverTapService.shared.logoutCurrentUser(firebaseUserID: previousUserID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAdminStatus() {
        Task {
            let status = await resolveAdminStatus()
            await MainActor.run {
                self.isAdmin = status
            }
        }
    }

    private func resolveAdminStatus() async -> Bool {
        guard let user = Auth.auth().currentUser else { return false }

        if let email = user.email?.lowercased(), email == adminEmail.lowercased() {
            return true
        }

        if let claims = await fetchCustomClaims(for: user) {
            if let isAdminClaim = claims["admin"] as? Bool, isAdminClaim {
                return true
            }
            if let role = claims["role"] as? String, role.lowercased() == "admin" {
                return true
            }
        }

        return false
    }

    private func fetchCustomClaims(for user: User) async -> [String: Any]? {
        await withCheckedContinuation { continuation in
            user.getIDTokenResult(forcingRefresh: false) { result, _ in
                continuation.resume(returning: result?.claims)
            }
        }
    }

    private static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
} 
