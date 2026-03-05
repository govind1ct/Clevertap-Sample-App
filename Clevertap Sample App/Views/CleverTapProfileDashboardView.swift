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

    private var lastRefreshText: String {
        if let updated = profileData["Last Profile Update"] {
            return formatPropertyValue(updated)
        }
        return "Just now"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("CleverTapPrimary").opacity(0.22),
                        Color("CleverTapSecondary").opacity(0.14),
                        Color(.systemGroupedBackground),
                        Color(.systemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color("CleverTapPrimary").opacity(0.20))
                    .frame(width: 280, height: 280)
                    .blur(radius: 52)
                    .offset(x: -140, y: -340)

                Circle()
                    .fill(Color("CleverTapSecondary").opacity(0.16))
                    .frame(width: 220, height: 220)
                    .blur(radius: 46)
                    .offset(x: 140, y: -260)
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        if isLoading {
                            VStack(spacing: 14) {
                                ProgressView()
                                    .controlSize(.large)
                                Text("Loading profile data...")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 44)
                            .dashboardSectionCard()
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
                    .padding(.top, 8)
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CleverTap Profile Dashboard")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Analytics, identity health and consent overview")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            HStack(spacing: 10) {
                DashboardPill(title: "Properties", value: "\(profileData.count)", icon: "slider.horizontal.3")
                DashboardPill(title: "Push", value: (profileData["MSG-push"] as? Bool == false) ? "Off" : "On", icon: "bell.fill")
                DashboardPill(title: "Sync", value: isSyncing ? "Running" : "Idle", icon: "arrow.triangle.2.circlepath")
            }

            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("CleverTapPrimary"))
                Text("Last refresh: \(lastRefreshText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.white.opacity(0.6), in: Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    .white.opacity(0.92),
                    Color("CleverTapPrimary").opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.65), lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 10)
        .padding(.top, 8)
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
        .dashboardSectionCard(padding: sectionPadding)
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
        .dashboardSectionCard(padding: sectionPadding)
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
                    value: "\(intValue(for: "App Launches"))",
                    icon: "app.badge",
                    color: .blue
                )
                
                MetricCard(
                    title: "Screen Views",
                    value: "\(intValue(for: "Total Screen Views"))",
                    icon: "eye.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Cart Additions",
                    value: "\(intValue(for: "Cart Additions"))",
                    icon: "cart.badge.plus",
                    color: .orange
                )
                
                MetricCard(
                    title: "Searches",
                    value: "\(intValue(for: "Total Searches"))",
                    icon: "magnifyingglass",
                    color: .purple
                )
            }
        }
        .dashboardSectionCard(padding: sectionPadding)
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
                    value: "\(intValue(for: "Total Orders"))",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                MetricRow(
                    title: "Total Spent",
                    value: "₹\(Int(doubleValue(for: "Total Spent")))",
                    icon: "indianrupeesign.circle.fill",
                    color: .green
                )
                
                MetricRow(
                    title: "Average Order Value",
                    value: "₹\(Int(doubleValue(for: "Average Order Value")))",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                MetricRow(
                    title: "Loyalty Points",
                    value: "\(intValue(for: "Loyalty Points"))",
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
        .dashboardSectionCard(padding: sectionPadding)
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
        .dashboardSectionCard(padding: sectionPadding)
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
        .dashboardSectionCard(padding: sectionPadding)
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

    private func intValue(for key: String) -> Int {
        if let value = profileData[key] as? Int {
            return value
        }
        if let value = profileData[key] as? NSNumber {
            return value.intValue
        }
        if let value = profileData[key] as? String, let intValue = Int(value) {
            return intValue
        }
        return 0
    }

    private func doubleValue(for key: String) -> Double {
        if let value = profileData[key] as? Double {
            return value
        }
        if let value = profileData[key] as? NSNumber {
            return value.doubleValue
        }
        if let value = profileData[key] as? String, let doubleValue = Double(value) {
            return doubleValue
        }
        return 0
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color("CleverTapPrimary").opacity(0.16))
                    .frame(width: 34, height: 34)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 0.8)
        )
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
                .frame(width: 44, height: 44)
                .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            
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
        .background(
            LinearGradient(
                colors: [
                    color.opacity(0.12),
                    Color(.secondarySystemBackground).opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.45), lineWidth: 0.8)
        )
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
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 34, height: 34)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 0.8)
        )
    }
}

struct NotificationStatusRow: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill((isEnabled ? Color.green : Color.red).opacity(0.16))
                    .frame(width: 34, height: 34)
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
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.5), lineWidth: 0.8)
        )
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
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.16))
                        .frame(width: 42, height: 42)
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
            .background(
                LinearGradient(
                    colors: [
                        color.opacity(0.12),
                        Color(.secondarySystemBackground).opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.45), lineWidth: 0.8)
            )
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
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.16),
                    Color("CleverTapSecondary").opacity(0.10)
                ],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.55), lineWidth: 0.8)
        )
    }
}

private extension View {
    func dashboardSectionCard(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .background(
                LinearGradient(
                    colors: [
                        .white.opacity(0.88),
                        Color(.secondarySystemBackground).opacity(0.76)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
    }
}

#Preview {
    CleverTapProfileDashboardView()
} 
