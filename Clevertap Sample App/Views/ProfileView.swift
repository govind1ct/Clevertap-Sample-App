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
    @State private var animateContent = false
    
    enum ActiveSheet: Identifiable {
        case editProfile, notificationSettings, cleverTapDashboard, settings
        var id: Int {
            switch self {
            case .editProfile: return 0
            case .notificationSettings: return 1
            case .cleverTapDashboard: return 2
            case .settings: return 3
            }
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    @Environment(\.colorScheme) var colorScheme

    private var totalSpentValue: Int {
        Int(orders.reduce(0) { $0 + $1.total })
    }

    private var profileCompletionValue: Int {
        calculateProfileCompletion()
    }

    private var membershipTierValue: String {
        determineMembershipTier()
    }

    private var isCompactScreen: Bool {
        UIScreen.main.bounds.height <= 750
    }

    private var horizontalInset: CGFloat {
        isCompactScreen ? 16 : 20
    }

    private var contentSectionSpacing: CGFloat {
        isCompactScreen ? 22 : 28
    }

    private var contentTopPadding: CGFloat {
        isCompactScreen ? 14 : 20
    }

    private var contentBottomPadding: CGFloat {
        isCompactScreen ? 28 : 40
    }

    private var heroCardPadding: CGFloat {
        isCompactScreen ? 22 : 30
    }

    private var sectionCardPadding: CGFloat {
        isCompactScreen ? 16 : 20
    }

    private let membershipTierOptions = ["Bronze", "Silver", "Gold"]
    
    var body: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.16),
                    Color("CleverTapSecondary").opacity(0.10),
                    Color(.systemBackground),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color("CleverTapPrimary").opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -140, y: -320)

            Circle()
                .fill(Color("CleverTapSecondary").opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 55)
                .offset(x: 160, y: -260)

            ScrollView(showsIndicators: false) {
                VStack(spacing: contentSectionSpacing) {

                    headerSection
                    userProfileCard

                    ProfileNativeDisplayView()
                        .padding(.horizontal, horizontalInset)

                    profileManagementSection
                    cleverTapIntegrationSection
                    orderHistorySection
                    logoutButton
                }
                .padding(.top, contentTopPadding)
                .padding(.bottom, contentBottomPadding)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 10)
                .animation(.spring(response: 0.45, dampingFraction: 0.86), value: animateContent)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !animateContent {
                animateContent = true
            }
            fetchUserData()
            CleverTapService.shared.trackScreenViewed(screenName: "Profile")
            CleverTapService.shared.addToMultiValueProperty(key: "Features Used", value: "Profile Management")
        }
        .refreshable {
            CleverTapService.shared.trackEvent("Profile Refreshed", withProps: [
                "Source": "pull_to_refresh"
            ])
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
            case .settings:
                SettingsView()
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("Account")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())

                    Text("Profile Hub")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.75)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Manage identity, preferences, and CleverTap sync in one place.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        openEditProfile(source: "header_icon")
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(ScalePressButtonStyle())

                    Button {
                        openSettings(source: "header_settings")
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(ScalePressButtonStyle())
                }
            }
            .padding(.horizontal, horizontalInset)
        }

    // MARK: - User Profile Card
        var userProfileCard: some View {
            VStack(spacing: 20) {

                if isLoadingProfile {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.vertical, 40)
                } else {

                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top, spacing: 16) {
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
                                    .frame(width: 92, height: 92)
                                    .shadow(color: Color("CleverTapPrimary").opacity(0.34),
                                            radius: 16, y: 8)

                                if let resolvedProfilePhotoURL = resolveProfileImageURL(from: profileService.userProfile.photoURL), !profileService.userProfile.photoURL.isEmpty {
                                    AsyncImage(url: resolvedProfilePhotoURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        profileInitials
                                    }
                                    .frame(width: 92, height: 92)
                                    .clipShape(Circle())
                                } else {
                                    profileInitials
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(profileService.userProfile.name.isEmpty ? "User" : profileService.userProfile.name)
                                    .font(.title3.weight(.semibold))

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

                            Spacer()
                        }

                        HStack(spacing: 10) {
                            ProfileMetricChip(title: "Orders", value: "\(orders.count)", icon: "bag.fill")
                            ProfileMetricChip(title: "Spent", value: "₹\(totalSpentValue)", icon: "creditcard.fill")
                            ProfileMetricChip(title: "Tier", value: membershipTierValue, icon: "crown.fill")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Profile Completion")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(profileCompletionValue)%")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(Color("CleverTapPrimary"))
                            }

                            ProgressView(value: Double(profileCompletionValue), total: 100)
                                .tint(Color("CleverTapPrimary"))
                        }

                        HStack(spacing: 12) {
                            Button {
                                openEditProfile(source: "hero_edit_profile")
                            } label: {
                                Label("Edit Profile", systemImage: "square.and.pencil")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color("CleverTapPrimary"),
                                                Color("CleverTapSecondary")
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(ScalePressButtonStyle())

                            Button {
                                openNotificationSettings(source: "hero_alerts")
                            } label: {
                                Label("Alerts", systemImage: "bell.badge.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(ScalePressButtonStyle())
                        }

                        Button {
                            openCleverTapDashboard(source: "hero_dashboard")
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(Color("CleverTapPrimary").opacity(0.16))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "chart.bar.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(Color("CleverTapPrimary"))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("CleverTap Dashboard")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.primary)
                                    Text("View live profile analytics")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 11)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(ScalePressButtonStyle())
                    }
                    .padding(heroCardPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .padding(.horizontal, horizontalInset)
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

            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color("CleverTapPrimary"))
                    Text("\(profileCompletionValue)% Complete")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())

                Spacer()

                Menu {
                    ForEach(membershipTierOptions, id: \.self) { tier in
                        Button {
                            profileService.updateMembershipTier(tier)
                            CleverTapService.shared.trackEvent("Profile Membership Tier Updated", withProps: [
                                "Tier": tier,
                                "Source": "profile_management_menu"
                            ])
                            syncStatusMessage = "Membership tier updated to \(tier)."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                syncStatusMessage = nil
                            }
                        } label: {
                            if membershipTierValue == tier {
                                Label(tier, systemImage: "checkmark")
                            } else {
                                Text(tier)
                            }
                        }
                    }
                } label: {
                    Label(membershipTierValue, systemImage: "crown.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.yellow.opacity(0.15), in: Capsule())
                }
                .buttonStyle(ScalePressButtonStyle())

                Button {
                    openEditProfile(source: "profile_management_edit_all")
                } label: {
                    Label("Edit All", systemImage: "square.and.pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("CleverTapPrimary").opacity(0.10), in: Capsule())
                }
                .buttonStyle(ScalePressButtonStyle())
            }
            
            VStack(spacing: 12) {
                ProfileInfoRow(
                    title: "Full Name",
                    value: profileService.userProfile.name.isEmpty ? "Not set" : profileService.userProfile.name,
                    icon: "person.fill",
                    onEdit: { openEditProfile(source: "profile_info_full_name") }
                )
                
                ProfileInfoRow(
                    title: "Phone",
                    value: profileService.userProfile.phone.isEmpty ? "Not set" : profileService.userProfile.phone,
                    icon: "phone.fill",
                    onEdit: { openEditProfile(source: "profile_info_phone") }
                )
                
                ProfileInfoRow(
                    title: "Location",
                    value: profileService.userProfile.location.isEmpty ? "Not set" : profileService.userProfile.location,
                    icon: "location.fill",
                    onEdit: { openEditProfile(source: "profile_info_location") }
                )
                
                ProfileInfoRow(
                    title: "Date of Birth",
                    value: profileService.userProfile.dateOfBirth != nil ? formatDate(profileService.userProfile.dateOfBirth!) : "Not set",
                    icon: "calendar",
                    onEdit: { openEditProfile(source: "profile_info_dob") }
                )
                
                ProfileInfoRow(
                    title: "Gender",
                    value: profileService.userProfile.gender.isEmpty ? "Not set" : profileService.userProfile.gender,
                    icon: "person.2.fill",
                    onEdit: { openEditProfile(source: "profile_info_gender") }
                )
            }
        }
        .padding(sectionCardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, horizontalInset)
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
        .padding(sectionCardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, horizontalInset)
    }
    
    // MARK: - CleverTap Integration Section
    private var cleverTapIntegrationSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "CleverTap Integration",
                subtitle: "Advanced analytics and personalization"
            )

            Button {
                triggerProfileSync()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 40, height: 40)
                        if isSyncingProfile {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.headline.weight(.semibold))
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(isSyncingProfile ? "Syncing Profile..." : "Sync Profile Data")
                            .font(.subheadline.weight(.semibold))
                        Text("Push latest profile and preference updates to CleverTap")
                            .font(.caption)
                            .opacity(0.9)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .opacity(0.9)
                }
                .foregroundColor(.white)
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(isSyncingProfile)
            .buttonStyle(ScalePressButtonStyle())
            
            VStack(spacing: 12) {
                CleverTapActionCard(
                    title: "Profile Dashboard",
                    subtitle: "View detailed analytics",
                    icon: "chart.bar.fill",
                    color: .blue
                ) {
                    openCleverTapDashboard(source: "ct_integration_dashboard_card")
                }
                
                CleverTapActionCard(
                    title: "Test Notifications",
                    subtitle: "Send test campaigns",
                    icon: "bell.badge",
                    color: .orange
                ) {
                    CleverTapService.shared.trackEvent("Profile Test Notifications Triggered", withProps: [
                        "Source": "ct_integration_card"
                    ])
                    CleverTapInAppService.shared.triggerPushNotification()
                }
                
                CleverTapActionCard(
                    title: "Test DOB Update",
                    subtitle: "Debug date of birth sync",
                    icon: "calendar.badge.clock",
                    color: .purple
                ) {
                    if let dob = profileService.userProfile.dateOfBirth {
                        CleverTapService.shared.trackEvent("Profile Test DOB Triggered", withProps: [
                            "Source": "ct_integration_card"
                        ])
                        CleverTapService.shared.updateDateOfBirth(dob)
                        CleverTapService.shared.debugProfileData()
                    } else {
                        CleverTapService.shared.trackEvent("Profile Test DOB Missing", withProps: [
                            "Source": "ct_integration_card"
                        ])
                        openEditProfile(source: "ct_integration_missing_dob")
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
                .transition(.opacity)
            }
        }
        .padding(sectionCardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, horizontalInset)
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
                } else if !orders.isEmpty {
                    NavigationLink {
                        OrderHistoryView(orders: orders)
                    } label: {
                        Text("View All")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color("CleverTapPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(ScalePressButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        CleverTapService.shared.trackEvent("Profile View All Orders Opened", withProps: [
                            "Order Count": orders.count
                        ])
                    })
                }
            }

            if !isLoadingOrders && !orders.isEmpty {
                HStack(spacing: 10) {
                    ProfileMetricChip(title: "Total Orders", value: "\(orders.count)", icon: "cart.fill")
                    ProfileMetricChip(title: "Total Spend", value: "₹\(Int(orders.reduce(0) { $0 + $1.total }))", icon: "indianrupeesign.circle.fill")
                    ProfileMetricChip(title: "Latest", value: orders.first?.status.capitalized ?? "-", icon: "clock.arrow.circlepath")
                }
                .transition(.opacity)
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
                        .buttonStyle(ScalePressButtonStyle())
                        .simultaneousGesture(TapGesture().onEnded {
                            CleverTapService.shared.trackEvent("Profile Order Detail Opened", withProps: [
                                "Order ID": order.id ?? "Unknown",
                                "Order Status": order.status
                            ])
                        })
                    }
                }
            }
        }
        .padding(sectionCardPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .padding(.horizontal, horizontalInset)
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        Button(action: {
            CleverTapService.shared.trackScreenViewed(screenName: "Logout")
            CleverTapService.shared.trackEvent("Profile Sign Out Tapped")
            authViewModel.signOut()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 34, height: 34)

                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)

                    Text("Securely end this session")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.95), Color.orange.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .red.opacity(0.22), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(ScalePressButtonStyle())
        .padding(.horizontal, horizontalInset)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods

    private func openEditProfile(source: String) {
        CleverTapService.shared.trackEvent("Profile Edit Opened", withProps: [
            "Source": source
        ])
        activeSheet = .editProfile
    }

    private func openNotificationSettings(source: String) {
        CleverTapService.shared.trackEvent("Profile Alerts Opened", withProps: [
            "Source": source
        ])
        activeSheet = .notificationSettings
    }

    private func openCleverTapDashboard(source: String) {
        CleverTapService.shared.trackEvent("Profile Dashboard Opened", withProps: [
            "Source": source
        ])
        activeSheet = .cleverTapDashboard
    }

    private func openSettings(source: String) {
        CleverTapService.shared.trackEvent("Profile Settings Opened", withProps: [
            "Source": source
        ])
        activeSheet = .settings
    }
    
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
            CleverTapService.shared.trackEvent("Profile Data Loaded", withProps: [
                "Orders Count": self.orders.count,
                "Profile Completion": self.calculateProfileCompletion(),
                "Membership Tier": self.membershipTierValue
            ])
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
                "Membership Tier": membershipTierValue
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
        
        CleverTapService.shared.trackEvent("Profile Sync Triggered", withProps: [
            "Source": "profile_sync_cta"
        ])
        isSyncingProfile = true
        syncStatusMessage = "Syncing profile data..."
        syncCleverTapProfile()

        if let user = authViewModel.user {
            CleverTapService.shared.createUserProfile(
                email: user.email ?? "",
                userId: user.uid,
                name: profileService.userProfile.name.isEmpty ? (user.displayName ?? "") : profileService.userProfile.name,
                isNewUser: false
            )
        }

        profileService.fetchUserProfile { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let didSync = profileService.forceCleverTapSync()
                isSyncingProfile = false
                syncStatusMessage = didSync ? "Profile synced successfully" : "Profile sync failed. Please login again."
                CleverTapService.shared.trackEvent("Profile Sync Result", withProps: [
                    "Success": didSync
                ])

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    syncStatusMessage = nil
                }
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
        let storedTier = profileService.userProfile.membershipTier
        if ["Bronze", "Silver", "Gold"].contains(storedTier) {
            return storedTier
        }

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

struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct ProfileMetricChip: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

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
        .buttonStyle(ScalePressButtonStyle())
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
                .font(.title3.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .background(Color("CleverTapPrimary").opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
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
                    .font(.title3.weight(.semibold))
                    .foregroundColor(color)
                    .frame(width: 42, height: 42)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                
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
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .buttonStyle(ScalePressButtonStyle())
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
                .font(.title3.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .background(Color("CleverTapPrimary").opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                .font(.title3.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .background(Color("CleverTapPrimary").opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
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
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("CleverTapPrimary").opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(ScalePressButtonStyle())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    private var isCompactScreen: Bool {
        UIScreen.main.bounds.height <= 750
    }

    private var horizontalInset: CGFloat {
        isCompactScreen ? 16 : 20
    }

    private var sectionSpacing: CGFloat {
        isCompactScreen ? 16 : 20
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
                    Color("CleverTapPrimary").opacity(0.13),
                    Color("CleverTapSecondary").opacity(0.08),
                    Color(.systemBackground),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color("CleverTapPrimary").opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: -130, y: -330)

            Circle()
                .fill(Color("CleverTapSecondary").opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 42)
                .offset(x: 180, y: -260)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: sectionSpacing) {
                    
                    // Header / status card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Order Snapshot")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("CleverTapPrimary"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())
                            
                            Spacer()
                            
                            StatusBadge(status: currentStatus)
                        }
                        
                        Text("Order #\(order.id ?? "Unknown")")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("₹\(Int(order.total))")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(amountGradient)
                            Text("total")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 10) {
                            orderMetaChip(
                                icon: "calendar",
                                title: formattedDate
                            )
                            orderMetaChip(
                                icon: "shippingbox.fill",
                                title: "\(itemCount) items"
                            )
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(currentStatus.lowercased() != "cancelled" ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(statusDescription(for: currentStatus))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                    
                    // Shipping address
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Delivery", systemImage: "location.fill")
                                .font(.headline)
                            Spacer()
                            Text(order.paymentMethod)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(shippingAddressLines, id: \.self) { line in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 5))
                                        .foregroundColor(Color("CleverTapPrimary"))
                                        .padding(.top, 7)
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                    
                    // Items
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Items")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(itemCount) total")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color("CleverTapPrimary"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                        }
                        
                        ForEach(order.items) { item in
                            OrderItemRow(item: item)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
                    )
                    
                    // Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Summary")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        summaryRow(title: "Items", value: "\(itemCount)")
                        summaryRow(title: "Shipping", value: "Free")
                        summaryRow(title: "Payment", value: order.paymentMethod)

                        Divider().opacity(0.22)
                        
                        HStack {
                            Text("Order Total")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("₹\(Int(order.total))")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(amountGradient)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.24), lineWidth: 1)
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
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
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
                                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.red.opacity(0.22), lineWidth: 1)
                                )
                                .foregroundColor(.red)
                            }
                            .disabled(isCancelling)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, horizontalInset)
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

    private func orderMetaChip(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(.secondarySystemBackground).opacity(0.85), in: Capsule())
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
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
                    .fill(.regularMaterial)
                    .frame(width: 54, height: 54)
                
                if !item.product.mainImageURL.isEmpty,
                   let url = URL(string: item.product.mainImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.clear
                    }
                    .frame(width: 54, height: 54)
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
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
