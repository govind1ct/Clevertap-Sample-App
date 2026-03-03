import SwiftUI
import CleverTapSDK

struct CleverTapProfileDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileData: [String: Any] = [:]
    @State private var isLoading = true
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showProfile = false
    @State private var showAuth = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        Color("CleverTapPrimary").opacity(0.05),
                        Color("CleverTapSecondary").opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
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
                    .padding(.horizontal, 20)
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
            // CleverTap Logo/Icon
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
                
                Text("Comprehensive user analytics and insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
                    title: "Sync Profile Data",
                    subtitle: "Update CleverTap with latest data",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue
                ) {
                    syncProfileData()
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
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        CleverTapService.shared.setUserProperty(key: "Manual Sync", value: Date())
        loadProfileData()
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
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
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
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
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
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            
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
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct NotificationStatusRow: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? .green : .red)
                .frame(width: 24)
            
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
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                
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
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CleverTapProfileDashboardView()
} 
