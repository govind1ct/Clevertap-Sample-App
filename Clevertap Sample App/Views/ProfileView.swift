import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var orderService = OrderService()
    @StateObject private var profileService = ProfileService()
    
    @State private var orders: [Order] = []
    @State private var isLoadingOrders = false
    @State private var isLoadingProfile = false
    @State private var isSyncingProfile = false
    @State private var syncStatusMessage: String?
    
    enum ActiveSheet: Identifiable {
        case editProfile, notificationSettings, cleverTapDashboard
        var id: Int {
            switch self {
            case .editProfile: return 0
            case .notificationSettings: return 1
            case .cleverTapDashboard: return 2
            }
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.07),
                    Color("CleverTapSecondary").opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    headerSection
                    userProfileCard
                   // cleverTapStatsSection
                    
                    ProfileNativeDisplayView()
                        .padding(.horizontal, 20)
                    
                   // quickStatsSection
                    profileManagementSection
                    notificationPreferencesSection
                    cleverTapIntegrationSection
                    orderHistorySection
                    logoutButton
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            fetchUserData()
            CleverTapService.shared.trackScreenViewed(screenName: "Profile")
            CleverTapService.shared.addToMultiValueProperty(key: "Features Used", value: "Profile Management")
        }
        .refreshable {
            await refreshUserData()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editProfile:
                EditProfileView(profileService: profileService)
                    .ignoresSafeArea(.keyboard)
                    .presentationDetents([.medium, .large])
            case .notificationSettings:
                NotificationSettingsView()
                    .ignoresSafeArea(.keyboard)
                    .presentationDetents([.medium, .large])
            case .cleverTapDashboard:
                CleverTapProfileDashboardView()
                    .ignoresSafeArea(.keyboard)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}


    // MARK: - Header Section
    private extension ProfileView {
        
        var headerSection: some View {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Profile")
                        .font(.system(size: 30, weight: .bold))
                    
                    Text("Manage your account & preferences")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    activeSheet = .cleverTapDashboard
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(.regularMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 20)
        }

    // MARK: - User Profile Card
        var userProfileCard: some View {
            VStack(spacing: 20) {
                
                if isLoadingProfile {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.vertical, 40)
                } else {
                    
                    VStack(spacing: 18) {
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color("CleverTapPrimary"),
                                            Color("CleverTapSecondary")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .shadow(color: Color("CleverTapPrimary").opacity(0.4),
                                        radius: 18, y: 10)
                            
                            if let resolvedProfilePhotoURL = resolveProfileImageURL(from: profileService.userProfile.photoURL), !profileService.userProfile.photoURL.isEmpty {
                                AsyncImage(url: resolvedProfilePhotoURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    profileInitials
                                }
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                            } else {
                                profileInitials
                            }
                        }
                        
                        VStack(spacing: 6) {
                            Text(profileService.userProfile.name.isEmpty ? "User" : profileService.userProfile.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let user = authViewModel.user {
                                Text(user.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Member since \(formatJoinDate(user.metadata.creationDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let cleverTapID = CleverTapService.shared.getUserID() {
                                Text("CT ID: \(String(cleverTapID.prefix(8)))...")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                        
                        Button {
                            activeSheet = .editProfile
                        } label: {
                            Text("Edit Profile")
                                .fontWeight(.medium)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color("CleverTapPrimary"),
                                            Color("CleverTapSecondary")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                                .foregroundColor(.white)
                        }
                    }
                    .padding(30)
                }
            }
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 20)
        }
        
        var profileInitials: some View {
            Text(getInitials())
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }

    
    // MARK: - CleverTap Stats Section
        struct CleverTapStatCard: View {
            let title: String
            let value: String
            let icon: String
            let color: Color
            
            var body: some View {
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .frame(width: 42, height: 42)
                        .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            }
        }

    
    // MARK: - Quick Stats Section
        struct StatCard: View {
            let title: String
            let value: String
            let icon: String
            let color: Color
            
            var body: some View {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    
                    Text(value)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }

    
    // MARK: - Profile Management Section
    private var profileManagementSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Profile Management",
                subtitle: "Update your personal information"
            )
            
            VStack(spacing: 12) {
                ProfileInfoRow(
                    title: "Full Name",
                    value: profileService.userProfile.name.isEmpty ? "Not set" : profileService.userProfile.name,
                    icon: "person.fill",
                    onEdit: { activeSheet = .editProfile }
                )
                
                ProfileInfoRow(
                    title: "Phone",
                    value: profileService.userProfile.phone.isEmpty ? "Not set" : profileService.userProfile.phone,
                    icon: "phone.fill",
                    onEdit: { activeSheet = .editProfile }
                )
                
                ProfileInfoRow(
                    title: "Location",
                    value: profileService.userProfile.location.isEmpty ? "Not set" : profileService.userProfile.location,
                    icon: "location.fill",
                    onEdit: { activeSheet = .editProfile }
                )
                
                ProfileInfoRow(
                    title: "Date of Birth",
                    value: profileService.userProfile.dateOfBirth != nil ? formatDate(profileService.userProfile.dateOfBirth!) : "Not set",
                    icon: "calendar",
                    onEdit: { activeSheet = .editProfile }
                )
                
                ProfileInfoRow(
                    title: "Gender",
                    value: profileService.userProfile.gender.isEmpty ? "Not set" : profileService.userProfile.gender,
                    icon: "person.2.fill",
                    onEdit: { activeSheet = .editProfile }
                )
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Notification Preferences Section
    private var notificationPreferencesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Notification Preferences",
                subtitle: "Manage your communication settings"
            )
            
            VStack(spacing: 12) {
                NotificationToggleRow(
                    title: "Push Notifications",
                    subtitle: "Receive app notifications",
                    isEnabled: profileService.userProfile.pushNotificationsEnabled,
                    icon: "bell.fill"
                ) { enabled in
                    profileService.updateNotificationPreference(type: "push", enabled: enabled)
                    CleverTapService.shared.setPushDND(enabled: !enabled)
                }

                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.top, 1)

                    Text("This toggle updates your CleverTap push preference (MSG-push). It does not change iOS notification permission. To fully disable notifications, use iPhone Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                
                NotificationToggleRow(
                    title: "Email Notifications",
                    subtitle: "Receive email updates",
                    isEnabled: profileService.userProfile.emailNotificationsEnabled,
                    icon: "envelope.fill"
                ) { enabled in
                    profileService.updateNotificationPreference(type: "email", enabled: enabled)
                    CleverTapService.shared.setEmailDND(enabled: !enabled)
                }
                
                NotificationToggleRow(
                    title: "SMS Notifications",
                    subtitle: "Receive SMS updates",
                    isEnabled: profileService.userProfile.smsNotificationsEnabled,
                    icon: "message.fill"
                ) { enabled in
                    profileService.updateNotificationPreference(type: "sms", enabled: enabled)
                    CleverTapService.shared.setSMSDND(enabled: !enabled)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - CleverTap Integration Section
    private var cleverTapIntegrationSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "CleverTap Integration",
                subtitle: "Advanced analytics and personalization"
            )
            
            VStack(spacing: 12) {
                CleverTapActionCard(
                    title: "Profile Dashboard",
                    subtitle: "View detailed analytics",
                    icon: "chart.bar.fill",
                    color: .blue
                ) {
                    activeSheet = .cleverTapDashboard
                }
                
                CleverTapActionCard(
                    title: "Sync Profile Data",
                    subtitle: isSyncingProfile ? "Sync in progress..." : "Update CleverTap profile",
                    icon: "arrow.triangle.2.circlepath",
                    color: .green,
                    isDisabled: isSyncingProfile
                ) {
                    triggerProfileSync()
                }
                
                CleverTapActionCard(
                    title: "Test Notifications",
                    subtitle: "Send test campaigns",
                    icon: "bell.badge",
                    color: .orange
                ) {
                    CleverTapInAppService.shared.triggerPushNotification()
                }
                
                CleverTapActionCard(
                    title: "Test DOB Update",
                    subtitle: "Debug date of birth sync",
                    icon: "calendar.badge.clock",
                    color: .purple
                ) {
                    if let dob = profileService.userProfile.dateOfBirth {
                        CleverTapService.shared.updateDateOfBirth(dob)
                        CleverTapService.shared.debugProfileData()
                    } else {
                        activeSheet = .editProfile
                    }
                }
            }
            
            if let syncStatusMessage {
                HStack(spacing: 8) {
                    if isSyncingProfile {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Text(syncStatusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Order History
    private var orderHistorySection: some View {
        VStack(spacing: 16) {
            HStack {
                SectionHeader(
                    title: "Recent Orders",
                    subtitle: "Your order history"
                )
                
                Spacer()
                
                if isLoadingOrders {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if isLoadingOrders {
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        ModernShimmerOrderRow()
                    }
                }
                .transition(.opacity)
            } else if orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No orders yet")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Start shopping to see your orders here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(orders.prefix(3)) { order in
                        NavigationLink {
                            OrderDetailView(order: order)
                        } label: {
                            OrderRowView(order: order)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if orders.count > 3 {
                        NavigationLink {
                            OrderHistoryView(orders: orders)
                        } label: {
                            Text("View All Orders")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {
            CleverTapService.shared.trackScreenViewed(screenName: "Logout")
            authViewModel.signOut()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.red.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    
    private func fetchUserData(completion: (() -> Void)? = nil) {
        isLoadingProfile = true
        isLoadingOrders = true
        let group = DispatchGroup()
        
        // Fetch profile data
        group.enter()
        profileService.fetchUserProfile { success in
            DispatchQueue.main.async {
                isLoadingProfile = false
                if success {
                    syncCleverTapProfile()
                }
                group.leave()
            }
        }
        
        // Fetch orders
        group.enter()
        fetchOrders {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion?()
        }
    }
    
    private func refreshUserData() async {
        await withCheckedContinuation { continuation in
            fetchUserData {
                continuation.resume()
            }
        }
    }
    
    private func fetchOrders(completion: (() -> Void)? = nil) {
        guard let user = authViewModel.user else {
            isLoadingOrders = false
            completion?()
            return
        }
        
        orderService.fetchOrders(for: user.uid) { fetchedOrders in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.orders = fetchedOrders
                    self.isLoadingOrders = false
                }
                
                // Update CleverTap with order data
                CleverTapService.shared.updateEcommerceProfile(
                    totalOrders: fetchedOrders.count,
                    totalSpent: fetchedOrders.reduce(0) { $0 + $1.total },
                    averageOrderValue: fetchedOrders.isEmpty ? 0 : fetchedOrders.reduce(0) { $0 + $1.total } / Double(fetchedOrders.count),
                    lastOrderDate: fetchedOrders.first?.createdAt
                )
                completion?()
            }
        }
    }
    
    private func syncCleverTapProfile() {
        guard let user = authViewModel.user else { return }
        
        // Sync comprehensive profile data with CleverTap
        CleverTapService.shared.updateFullUserProfile(
            name: profileService.userProfile.name.isEmpty ? nil : profileService.userProfile.name,
            email: user.email,
            phone: profileService.userProfile.phone.isEmpty ? nil : profileService.userProfile.phone,
            gender: profileService.userProfile.gender.isEmpty ? nil : profileService.userProfile.gender,
            dateOfBirth: profileService.userProfile.dateOfBirth,
            location: profileService.userProfile.location.isEmpty ? nil : profileService.userProfile.location,
            customProperties: [
                "Firebase UID": user.uid,
                "Account Created": user.metadata.creationDate ?? Date(),
                "Last Login": user.metadata.lastSignInDate ?? Date(),
                "Profile Completion": calculateProfileCompletion(),
                "Membership Tier": determineMembershipTier()
            ]
        )
        
        // Update notification preferences
        CleverTapService.shared.updateEngagementProfile(
            pushOptIn: profileService.userProfile.pushNotificationsEnabled,
            emailOptIn: profileService.userProfile.emailNotificationsEnabled
        )
        
        // Track profile sync event
        CleverTapService.shared.setUserProperty(key: "Last Profile Sync", value: Date())
    }
    
    private func triggerProfileSync() {
        guard !isSyncingProfile else { return }
        
        isSyncingProfile = true
        syncStatusMessage = "Syncing profile data..."
        syncCleverTapProfile()
        let didSync = profileService.forceCleverTapSync()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSyncingProfile = false
            syncStatusMessage = didSync ? "Profile synced successfully" : "Profile sync failed. Please login again."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                syncStatusMessage = nil
            }
        }
    }
    
    private func getInitials() -> String {
        let name = profileService.userProfile.name.isEmpty ? (authViewModel.user?.email ?? "U") : profileService.userProfile.name
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    private func formatJoinDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func calculateProfileCompletion() -> Int {
        var completion = 0
        let profile = profileService.userProfile
        
        if !profile.name.isEmpty { completion += 20 }
        if !profile.phone.isEmpty { completion += 20 }
        if !profile.location.isEmpty { completion += 20 }
        if profile.dateOfBirth != nil { completion += 20 }
        if !profile.gender.isEmpty { completion += 20 }
        
        return completion
    }
    
    private func determineMembershipTier() -> String {
        let totalSpent = orders.reduce(0) { $0 + $1.total }
        let orderCount = orders.count
        
        if totalSpent >= 10000 || orderCount >= 10 {
            return "Gold"
        } else if totalSpent >= 5000 || orderCount >= 5 {
            return "Silver"
        } else {
            return "Bronze"
        }
    }

    private func resolveProfileImageURL(from value: String) -> URL? {
        guard !value.isEmpty else { return nil }
        if let url = URL(string: value), let scheme = url.scheme, !scheme.isEmpty {
            return url
        }
        return URL(fileURLWithPath: value)
    }
}

// MARK: - Supporting Views

struct ModernSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if let onEdit {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ModernOrderRow: View {
    let order: Order
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Order #\(order.id ?? "Unknown")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("₹\(Int(order.total))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(order.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: order.status)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatusBadge: View {
    let status: String
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "delivered": return .green
        case "shipped": return .blue
        case "processing": return .orange
        case "cancelled": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct EmptyOrdersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.7))
            
            VStack(spacing: 4) {
                Text("No orders yet")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Start shopping to see your orders here")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ModernShimmerOrderRow: View {
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .frame(width: 40, height: 40)
                .shimmering()
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 14)
                    .shimmering()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 12)
                    .shimmering()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 10)
                    .shimmering()
            }
            
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CleverTapStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CleverTapActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .buttonStyle(.plain)
    }
}

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let icon: String
    let action: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .init(
                get: { isEnabled },
                set: action
            ))
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ProfileInfoRow: View {
    let title: String
    let value: String
    let icon: String
    var onEdit: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let onEdit {
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        ModernOrderRow(order: order)
    }
}

struct OrderHistoryView: View {
    let orders: [Order]
    
    var body: some View {
        List {
            ForEach(orders) { order in
                NavigationLink {
                    OrderDetailView(order: order)
                } label: {
                    OrderRowView(order: order)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.07),
                    Color("CleverTapSecondary").opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("All Orders")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderDetailView: View {
    let order: Order
    
    @EnvironmentObject var cartManager: CartManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var orderService = OrderService()
    
    @State private var currentStatus: String
    @State private var isCancelling = false
    @State private var showCancelConfirmation = false
    @State private var actionError: String?
    
    init(order: Order) {
        self.order = order
        _currentStatus = State(initialValue: order.status)
    }
    
    private var itemCount: Int {
        order.items.reduce(0) { $0 + $1.quantity }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: order.createdAt)
    }
    
    private var amountGradient: LinearGradient {
        LinearGradient(
            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var canCancel: Bool {
        let lower = currentStatus.lowercased()
        return lower != "delivered" && lower != "cancelled"
    }
    
    private var shippingAddressLines: [String] {
        var lines: [String] = []
        if let name = order.shippingName, !name.isEmpty { lines.append(name) }
        if let street = order.shippingStreet, !street.isEmpty { lines.append(street) }
        var cityLine: [String] = []
        if let city = order.shippingCity, !city.isEmpty { cityLine.append(city) }
        if let pin = order.shippingPincode, !pin.isEmpty { cityLine.append(pin) }
        if !cityLine.isEmpty { lines.append(cityLine.joined(separator: " - ")) }
        if lines.isEmpty && !order.address.isEmpty {
            lines.append(order.address)
        }
        return lines
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.07),
                    Color("CleverTapSecondary").opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // Header / status card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Order #\(order.id ?? "Unknown")")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            StatusBadge(status: currentStatus)
                        }
                        
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(currentStatus.lowercased() != "cancelled" ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(statusDescription(for: currentStatus))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("₹\(Int(order.total))")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(amountGradient)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Shipping address
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Delivery")
                                .font(.headline)
                            Spacer()
                            if let method = order.paymentMethod as String? {
                                Text(method)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(shippingAddressLines, id: \.self) { line in
                                Text(line)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Items
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Items")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Divider().opacity(0.4)
                        
                        ForEach(order.items) { item in
                            OrderItemRow(item: item)
                                .padding(.vertical, 4)
                            
                            if item.id != order.items.last?.id {
                                Divider().opacity(0.15)
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("Items")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(itemCount)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Order Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("₹\(Int(order.total))")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(amountGradient)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Actions
                    if let error = actionError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    VStack(spacing: 12) {
                        Button {
                            handleReorder()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Reorder")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        
                        if canCancel {
                            Button {
                                showCancelConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text(isCancelling ? "Cancelling..." : "Cancel Order")
                                }
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                                .foregroundColor(.red)
                            }
                            .disabled(isCancelling)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
                .animation(.easeInOut(duration: 0.2), value: currentStatus)
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Cancel Order?", isPresented: $showCancelConfirmation) {
            Button("Keep Order", role: .cancel) { }
            Button("Cancel Order", role: .destructive) {
                performCancellation()
            }
        } message: {
            Text("Are you sure you want to cancel this order?")
        }
    }
    
    private func statusDescription(for status: String) -> String {
        switch status.lowercased() {
        case "processing":
            return "We're preparing your items."
        case "shipped":
            return "Your order is on the way."
        case "delivered":
            return "Order delivered. We hope you love it!"
        case "cancelled":
            return "This order was cancelled."
        default:
            return "Order status: \(status)"
        }
    }
    
    private func performCancellation() {
        guard let orderId = order.id,
              let userId = authViewModel.user?.uid else {
            actionError = "Unable to cancel this order."
            return
        }
        
        isCancelling = true
        actionError = nil
        
        orderService.updateOrderStatus(orderId: orderId, userId: userId, status: "Cancelled") { result in
            DispatchQueue.main.async {
                self.isCancelling = false
                switch result {
                case .success:
                    self.currentStatus = "Cancelled"
                    CleverTapService.shared.trackEvent("Order Cancelled", withProps: [
                        "Order ID": orderId,
                        "Total Amount": order.total
                    ])
                case .failure(let error):
                    self.actionError = error.localizedDescription
                }
            }
        }
    }
    
    private func handleReorder() {
        for item in order.items {
            cartManager.addToCart(item.product)
        }
        
        CleverTapService.shared.trackEvent("Order Reordered", withProps: [
            "Original Order ID": order.id ?? "",
            "Item Count": itemCount,
            "Total Amount": order.total
        ])
    }
}

struct OrderItemRow: View {
    let item: CartItem
    
    private var amountGradient: LinearGradient {
        LinearGradient(
            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                
                if !item.product.mainImageURL.isEmpty,
                   let url = URL(string: item.product.mainImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.clear
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text(String(item.product.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let shortDescription = item.product.shortDescription,
                   !shortDescription.isEmpty {
                    Text(shortDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Qty \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("₹\(Int(item.product.price * Double(item.quantity)))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(amountGradient)
            }
        }
    }
}
