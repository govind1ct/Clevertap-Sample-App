import SwiftUI
import CleverTapSDK

struct CleverTapProfileDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileData: [String: Any] = [:]
    @State private var isLoading = true
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var profileService = ProfileService()
    @State private var showProfile = false
    @State private var showAuth = false
    @State private var isSyncing = false
    @State private var syncStatusMessage: String?

    private var isCompactScreen: Bool {
        UIScreen.main.bounds.height <= 750
    }

    private var horizontalInset: CGFloat {
        isCompactScreen ? 16 : 20
    }

    private var sectionPadding: CGFloat {
        isCompactScreen ? 16 : 20
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("CleverTapPrimary").opacity(0.15),
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
                    .blur(radius: 40)
                    .offset(x: -130, y: -300)
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if isLoading {
                            ProgressView("Loading profile data...")
                                .frame(height: 200)
                        } else {
                            // CleverTap ID Section
                            cleverTapIDSection
                            
                            // User Properties Section
                            userPropertiesSection
                            
                            // Engagement Metrics
                            engagementMetricsSection
                            
                            // E-commerce Metrics
                            ecommerceMetricsSection
                            
                            // Notification Preferences
                            notificationPreferencesSection
                            
                            // Profile Actions
                            profileActionsSection
                        }
                    }
                    .padding(.horizontal, horizontalInset)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("CleverTap Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            if authViewModel.isAuthenticated {
                                showProfile = true
                            } else {
                                showAuth = true
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                        
                        Button("Refresh") {
                            CleverTapService.shared.trackEvent("Dashboard Refresh Tapped")
                            loadProfileData()
                        }
                    }
                }
            }
            .onAppear {
                loadProfileData()
                CleverTapService.shared.trackScreenViewed(screenName: "CleverTap Dashboard")
            }
            .sheet(isPresented: $showProfile) {
                NavigationView {
                    ProfileView()
                        .environmentObject(authViewModel)
                }
            }
            .sheet(isPresented: $showAuth) {
                AuthLoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("CleverTapPrimary").opacity(0.3),
                                Color("CleverTapSecondary").opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("CleverTap Profile Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Analytics, identity and preference health for this profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                DashboardPill(title: "Properties", value: "\(profileData.count)", icon: "slider.horizontal.3")
                DashboardPill(title: "Permission", value: (profileData["MSG-push"] as? Bool == false) ? "Off" : "On", icon: "bell.fill")
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - CleverTap ID Section
    private var cleverTapIDSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "CleverTap Identity",
                subtitle: "Your unique CleverTap identifier"
            )
            
            VStack(spacing: 12) {
                if let cleverTapID = CleverTap.sharedInstance()?.profileGetID() {
                    ProfileDataRow(
                        title: "CleverTap ID",
                        value: cleverTapID,
                        icon: "tag.fill",
                        copyable: true
                    )
                } else {
                    Text("CleverTap ID not available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                if let identity = profileData["Identity"] as? String {
                    ProfileDataRow(
                        title: "Identity",
                        value: identity,
                        icon: "person.badge.key.fill",
                        copyable: true
                    )
                }
                
                if let email = profileData["Email"] as? String {
                    ProfileDataRow(
                        title: "Email",
                        value: email,
                        icon: "envelope.fill",
                        copyable: true
                    )
                }
            }
        }
        .padding(sectionPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - User Properties Section
    private var userPropertiesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "User Properties",
                subtitle: "Personal information and preferences"
            )
            
            LazyVStack(spacing: 8) {
                ForEach(getUserProperties(), id: \.key) { property in
                    ProfileDataRow(
                        title: property.key,
                        value: formatPropertyValue(property.value),
                        icon: getIconForProperty(property.key)
                    )
                }
            }
        }
        .padding(sectionPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - Engagement Metrics Section
    private var engagementMetricsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Engagement Metrics",
                subtitle: "App usage and interaction data"
            )
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "App Launches",
                    value: "\(profileData["App Launches"] as? Int ?? 0)",
                    icon: "app.badge",
                    color: .blue
                )
                
                MetricCard(
                    title: "Screen Views",
                    value: "\(profileData["Total Screen Views"] as? Int ?? 0)",
                    icon: "eye.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Cart Additions",
                    value: "\(profileData["Cart Additions"] as? Int ?? 0)",
                    icon: "cart.badge.plus",
                    color: .orange
                )
                
                MetricCard(
                    title: "Searches",
                    value: "\(profileData["Total Searches"] as? Int ?? 0)",
                    icon: "magnifyingglass",
                    color: .purple
                )
            }
        }
        .padding(sectionPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - E-commerce Metrics Section
    private var ecommerceMetricsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "E-commerce Metrics",
                subtitle: "Shopping behavior and purchase data"
            )
            
            VStack(spacing: 12) {
                MetricRow(
                    title: "Total Orders",
                    value: "\(profileData["Total Orders"] as? Int ?? 0)",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                MetricRow(
                    title: "Total Spent",
                    value: "₹\(Int(profileData["Total Spent"] as? Double ?? 0))",
                    icon: "indianrupeesign.circle.fill",
                    color: .green
                )
                
                MetricRow(
                    title: "Average Order Value",
                    value: "₹\(Int(profileData["Average Order Value"] as? Double ?? 0))",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                MetricRow(
                    title: "Loyalty Points",
                    value: "\(profileData["Loyalty Points"] as? Int ?? 0)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                MetricRow(
                    title: "Membership Tier",
                    value: profileData["Membership Tier"] as? String ?? "Bronze",
                    icon: "crown.fill",
                    color: .purple
                )
            }
        }
        .padding(sectionPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - Notification Preferences Section
    private var notificationPreferencesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Notification Preferences",
                subtitle: "Communication settings and DND status"
            )
            
            VStack(spacing: 12) {
                NotificationStatusRow(
                    title: "Push Notifications",
                    isEnabled: !(profileData["MSG-push"] as? Bool == false),
                    icon: "bell.fill"
                )
                
                NotificationStatusRow(
                    title: "Email Notifications",
                    isEnabled: !(profileData["MSG-email"] as? Bool == false),
                    icon: "envelope.fill"
                )
                
                NotificationStatusRow(
                    title: "SMS Notifications",
                    isEnabled: !(profileData["MSG-sms"] as? Bool == false),
                    icon: "message.fill"
                )
                
                if let dndPhone = profileData["MSG-dndPhone"] as? Bool, dndPhone {
                    NotificationStatusRow(
                        title: "Phone DND",
                        isEnabled: false,
                        icon: "phone.down.fill"
                    )
                }
                
                if let dndEmail = profileData["MSG-dndEmail"] as? Bool, dndEmail {
                    NotificationStatusRow(
                        title: "Email DND",
                        isEnabled: false,
                        icon: "envelope.badge.fill"
                    )
                }
            }
        }
        .padding(sectionPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - Profile Actions Section
    private var profileActionsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Profile Actions",
                subtitle: "Manage your CleverTap profile"
            )
            
            VStack(spacing: 12) {
                ActionButton(
                    title: isSyncing ? "Syncing Profile..." : "Sync Profile Data",
                    subtitle: "Update CleverTap with latest profile and preferences",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue,
                    isDisabled: isSyncing
                ) {
                    syncProfileData()
                }

                if let syncStatusMessage {
                    Text(syncStatusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                ActionButton(
                    title: "Clear Profile Cache",
                    subtitle: "Reset local profile cache",
                    icon: "trash.fill",
                    color: .red
                ) {
                    clearProfileCache()
                }
                
                ActionButton(
                    title: "Export Profile Data",
                    subtitle: "Download profile information",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    exportProfileData()
                }
            }
        }
        .padding(sectionPadding)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadProfileData() {
        isLoading = true
        
        // Simulate loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Get all available profile properties from CleverTap
            let properties = [
                "Identity", "Email", "Name", "Phone", "Gender", "DOB", "Location",
                "Customer Type", "Preferred Language", "Membership Tier",
                "App Launches", "Total Screen Views", "Cart Additions", "Total Searches",
                "Total Orders", "Total Spent", "Average Order Value", "Loyalty Points",
                "MSG-push", "MSG-email", "MSG-sms", "MSG-dndPhone", "MSG-dndEmail",
                "Last Profile Update", "Last Order Date", "Registration Date"
            ]
            
            var data: [String: Any] = [:]
            for property in properties {
                if let value = CleverTapService.shared.getUserProperty(key: property) {
                    data[property] = value
                }
            }
            
            profileData = data
            isLoading = false
        }
    }
    
    private func getUserProperties() -> [(key: String, value: Any)] {
        let excludedKeys = ["MSG-push", "MSG-email", "MSG-sms", "MSG-dndPhone", "MSG-dndEmail"]
        return profileData.filter { !excludedKeys.contains($0.key) }
            .sorted { $0.key < $1.key }
            .map { (key: $0.key, value: $0.value) }
    }
    
    private func formatPropertyValue(_ value: Any) -> String {
        if let date = value as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if let number = value as? NSNumber {
            return number.stringValue
        } else {
            return String(describing: value)
        }
    }
    
    private func getIconForProperty(_ key: String) -> String {
        switch key.lowercased() {
        case "name": return "person.fill"
        case "email": return "envelope.fill"
        case "phone": return "phone.fill"
        case "gender": return "person.2.fill"
        case "dob", "date": return "calendar"
        case "location": return "location.fill"
        case "customer type": return "person.badge.key.fill"
        case "preferred language": return "globe"
        case "membership tier": return "crown.fill"
        case "loyalty points": return "star.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func syncProfileData() {
        guard !isSyncing else { return }
        isSyncing = true
        syncStatusMessage = "Sync in progress..."
        CleverTapService.shared.trackEvent("Dashboard Sync Triggered")

        if let user = authViewModel.user {
            CleverTapService.shared.createUserProfile(
                email: user.email ?? "",
                userId: user.uid,
                name: user.displayName ?? "",
                isNewUser: false
            )
        }

        profileService.fetchUserProfile { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let didSync = profileService.forceCleverTapSync()
                syncStatusMessage = didSync ? "Profile sync triggered." : "Profile sync failed. Please login again."
                CleverTapService.shared.trackEvent("Dashboard Sync Result", withProps: [
                    "Success": didSync
                ])
                loadProfileData()
                isSyncing = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    syncStatusMessage = nil
                }
            }
        }
    }
    
    private func clearProfileCache() {
        // This would clear local cache if implemented
        print("Profile cache cleared")
    }
    
    private func exportProfileData() {
        // This would export profile data if implemented
        print("Profile data exported")
    }
}

// MARK: - Supporting Views

struct ProfileDataRow: View {
    let title: String
    let value: String
    let icon: String
    var copyable: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color("CleverTapPrimary").opacity(0.13))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color("CleverTapPrimary"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if copyable {
                Button(action: {
                    UIPasteboard.general.string = value
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(Color("CleverTapPrimary"))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct NotificationStatusRow: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill((isEnabled ? Color.green : Color.red).opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isEnabled ? .green : .red)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(isEnabled ? "Enabled" : "Disabled")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isEnabled ? .green : .red, in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
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
            .padding(12)
            .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .buttonStyle(ScalePressButtonStyle())
    }
}

struct DashboardPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text("\(title): \(value)")
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(Color("CleverTapPrimary"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
    }
}

#Preview {
    CleverTapProfileDashboardView()
} 
