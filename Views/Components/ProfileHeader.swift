import SwiftUI

struct ProfileHeader: View {
    @EnvironmentObject var authManager: AuthManager
    var showEditButton: Bool = true
    var onEditTap: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            if let profileImage = authManager.currentUser?.profileImage {
                Image(profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if showEditButton {
                Button(action: {
                    onEditTap?()
                }) {
                    Text("Edit Profile")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ProfileHeader()
        .environmentObject(AuthManager())
} 