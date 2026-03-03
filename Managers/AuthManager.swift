import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?
    
    func signIn(email: String, password: String) {
        isLoading = true
        error = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // For demo purposes, accept any non-empty credentials
            if !email.isEmpty && !password.isEmpty {
                self.currentUser = User(
                    id: UUID().uuidString,
                    name: "Demo User",
                    email: email,
                    profileImage: nil
                )
                self.isAuthenticated = true
            } else {
                self.error = "Invalid credentials"
            }
            self.isLoading = false
        }
    }
    
    func signUp(name: String, email: String, password: String) {
        isLoading = true
        error = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // For demo purposes, accept any non-empty credentials
            if !name.isEmpty && !email.isEmpty && !password.isEmpty {
                self.currentUser = User(
                    id: UUID().uuidString,
                    name: name,
                    email: email,
                    profileImage: nil
                )
                self.isAuthenticated = true
            } else {
                self.error = "Please fill in all fields"
            }
            self.isLoading = false
        }
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
    }
}

struct User: Identifiable {
    let id: String
    let name: String
    let email: String
    var profileImage: String?
} 