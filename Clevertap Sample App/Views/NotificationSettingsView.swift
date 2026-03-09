import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileService = ProfileService()
    @State private var pushNotifications = true
    @State private var emailNotifications = true
    @State private var smsNotifications = false
    @State private var inAppNotifications = true
    @State private var marketingEmails = true
    @State private var orderUpdates = true
    @State private var promotionalSMS = false
    @State private var weeklyDigest = true
    @State private var groupSimilarNotifications = true
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var notificationStatus = "Checking..."
    @State private var deviceToken = "Not available"
    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var backgroundGradientColors: [Color] {
        if isDarkMode {
            return [
                Color(red: 0.10, green: 0.12, blue: 0.16),
                Color("CleverTapPrimary").opacity(0.22),
                Color(.systemBackground),
                Color(.systemBackground)
            ]
        }
        return [
            Color("CleverTapPrimary").opacity(0.18),
            Color("CleverTapSecondary").opacity(0.10),
            Color(.systemBackground),
            Color(.systemBackground)
        ]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: backgroundGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: 36)
                    .offset(x: -140, y: -320)

                Circle()
                    .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.10))
                    .frame(width: 300, height: 300)
                    .blur(radius: 48)
                    .offset(x: 160, y: -260)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // System Status
                        systemStatusSection
                        
                        // Primary Notification Settings
                        primaryNotificationSection
                        
                        // Email Preferences
                        emailPreferencesSection
                        
                        // SMS Preferences
                        smsPreferencesSection
                        
                        // Advanced Settings
                        advancedSettingsSection
                        
                        // CleverTap DND Settings
                        cleverTapDNDSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
                checkNotificationStatus()
                loadDeviceToken()
                CleverTapService.shared.trackScreenViewed(screenName: "Notification Settings")
            }
            .alert("Settings Updated", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your notification preferences have been updated successfully!")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTIFICATION CONTROL")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("CleverTapPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.14), in: Capsule())

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notification Settings")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Customize how you receive updates and communications.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                ZStack {
                    Circle()
                        .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.26 : 0.18))
                        .frame(width: 58, height: 58)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
        .padding(.top, 8)
    }
    
    // MARK: - System Status Section
    private var systemStatusSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "System Status",
                subtitle: "Current notification permissions and device info"
            )
            
            VStack(spacing: 12) {
                StatusRow(
                    title: "Permission Status",
                    value: notificationStatus,
                    icon: "shield.checkered",
                    color: notificationStatus == "Authorized" ? .green : .red
                )
                
                StatusRow(
                    title: "Device Token",
                    value: deviceToken == "Not available" ? "Not Available" : "Available",
                    icon: "iphone",
                    color: deviceToken == "Not available" ? .red : .green
                )
                
                if notificationStatus != "Authorized" {
                    Button("Request Permission") {
                        requestNotificationPermission()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
    }
    
    // MARK: - Primary Notification Section
    private var primaryNotificationSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Primary Notifications",
                subtitle: "Essential communication channels"
            )
            
            VStack(spacing: 12) {
                NotificationToggle(
                    title: "Push Notifications",
                    subtitle: "Receive app notifications on your device",
                    icon: "bell.fill",
                    isEnabled: $pushNotifications,
                    color: .blue
                ) {
                    CleverTapService.shared.setPushDND(enabled: !pushNotifications)
                    CleverTapService.shared.trackScreenViewed(screenName: "Push Toggle")
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
                
                NotificationToggle(
                    title: "In-App Notifications",
                    subtitle: "Show notifications while using the app",
                    icon: "app.badge",
                    isEnabled: $inAppNotifications,
                    color: .green
                ) {
                    CleverTapService.shared.trackScreenViewed(screenName: "InApp Toggle")
                }
                
                NotificationToggle(
                    title: "Email Notifications",
                    subtitle: "Receive updates via email",
                    icon: "envelope.fill",
                    isEnabled: $emailNotifications,
                    color: .orange
                ) {
                    CleverTapService.shared.setEmailDND(enabled: !emailNotifications)
                    // If user opts back in, clear address-level DND as well.
                    if emailNotifications {
                        CleverTapService.shared.setEmailAddressDND(enabled: false)
                    }
                    CleverTapService.shared.trackScreenViewed(screenName: "Email Toggle")
                }
                
                NotificationToggle(
                    title: "SMS Notifications",
                    subtitle: "Receive text message updates",
                    icon: "message.fill",
                    isEnabled: $smsNotifications,
                    color: .purple
                ) {
                    CleverTapService.shared.setSMSDND(enabled: !smsNotifications)
                    // If user opts back in, clear phone-level DND as well.
                    if smsNotifications {
                        CleverTapService.shared.setPhoneDND(enabled: false)
                    }
                    CleverTapService.shared.trackScreenViewed(screenName: "SMS Toggle")
                }
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
    }
    
    // MARK: - Email Preferences Section
    private var emailPreferencesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Email Preferences",
                subtitle: "Choose what emails you want to receive"
            )
            
            VStack(spacing: 12) {
                NotificationToggle(
                    title: "Order Updates",
                    subtitle: "Shipping and delivery notifications",
                    icon: "shippingbox.fill",
                    isEnabled: $orderUpdates,
                    color: .blue
                )
                
                NotificationToggle(
                    title: "Marketing Emails",
                    subtitle: "Promotional offers and new products",
                    icon: "megaphone.fill",
                    isEnabled: $marketingEmails,
                    color: .red
                )
                
                NotificationToggle(
                    title: "Weekly Digest",
                    subtitle: "Summary of your activity and recommendations",
                    icon: "calendar.badge.clock",
                    isEnabled: $weeklyDigest,
                    color: .green
                )
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
    }
    
    // MARK: - SMS Preferences Section
    private var smsPreferencesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "SMS Preferences",
                subtitle: "Text message notification settings"
            )
            
            VStack(spacing: 12) {
                NotificationToggle(
                    title: "Promotional SMS",
                    subtitle: "Special offers and discounts via SMS",
                    icon: "percent",
                    isEnabled: $promotionalSMS,
                    color: .orange
                )
                
                // SMS Frequency Selector
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        
                        Text("SMS Frequency")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(["Daily", "Weekly", "Monthly"], id: \.self) { frequency in
                            Button(frequency) {
                                CleverTapService.shared.setUserProperty(key: "SMS Frequency", value: frequency)
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.purple)
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
    }
    
    // MARK: - Advanced Settings Section
    private var advancedSettingsSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "Advanced Settings",
                subtitle: "Fine-tune your notification experience"
            )
            
            VStack(spacing: 12) {
                // Quiet Hours
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.title3)
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        
                        Text("Quiet Hours")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("10 PM - 8 AM")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("No notifications during these hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 36)
                }
                .padding(16)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                
                // Notification Grouping
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.title3)
                            .foregroundColor(.teal)
                            .frame(width: 24)
                        
                        Text("Group Similar Notifications")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Toggle("", isOn: $groupSimilarNotifications)
                            .scaleEffect(0.8)
                    }
                    
                    Text("Combine related notifications to reduce clutter")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 36)
                }
                .padding(16)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
    }
    
    // MARK: - CleverTap DND Section
    private var cleverTapDNDSection: some View {
        VStack(spacing: 16) {
            SectionHeader(
                title: "CleverTap DND Settings",
                subtitle: "Advanced Do Not Disturb configuration"
            )
            
            VStack(spacing: 12) {
                // Phone DND
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "phone.down.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Phone Number DND")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Block all SMS to this phone number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()

                        HStack(spacing: 8) {
                            Button("Enable") {
                                CleverTapService.shared.setPhoneDND(enabled: true)
                                CleverTapService.shared.trackScreenViewed(screenName: "Phone DND Enabled")
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.red)

                            Button("Disable") {
                                CleverTapService.shared.setPhoneDND(enabled: false)
                                CleverTapService.shared.trackScreenViewed(screenName: "Phone DND Disabled")
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.green)
                        }
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                
                // Email DND
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "envelope.badge.fill")
                            .font(.title3)
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email Address DND")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Block all emails to this address")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()

                        HStack(spacing: 8) {
                            Button("Enable") {
                                CleverTapService.shared.setEmailAddressDND(enabled: true)
                                CleverTapService.shared.trackScreenViewed(screenName: "Email DND Enabled")
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.orange)

                            Button("Disable") {
                                CleverTapService.shared.setEmailAddressDND(enabled: false)
                                CleverTapService.shared.trackScreenViewed(screenName: "Email DND Disabled")
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundColor(.green)
                        }
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                
                // Info Note
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("About DND Settings")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Text("DND settings apply to all users sharing the same phone number or email address. Use with caution.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .settingsSurfaceCard(isDarkMode: isDarkMode)
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveSettings) {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "checkmark")
                }
                
                Text(isSaving ? "Saving..." : "Save Preferences")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: Color("CleverTapPrimary").opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isSaving)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        profileService.fetchUserProfile { _ in
            DispatchQueue.main.async {
                let profile = profileService.userProfile
                pushNotifications = profile.pushNotificationsEnabled
                emailNotifications = profile.emailNotificationsEnabled
                smsNotifications = profile.smsNotificationsEnabled
            }
        }
        if UserDefaults.standard.object(forKey: "notifications.groupSimilar") != nil {
            groupSimilarNotifications = UserDefaults.standard.bool(forKey: "notifications.groupSimilar")
        } else {
            groupSimilarNotifications = true
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    notificationStatus = "Authorized"
                case .denied:
                    notificationStatus = "Denied"
                case .notDetermined:
                    notificationStatus = "Not Determined"
                case .provisional:
                    notificationStatus = "Provisional"
                case .ephemeral:
                    notificationStatus = "Ephemeral"
                @unknown default:
                    notificationStatus = "Unknown"
                }
                
                // Update CleverTap user profile
                CleverTapService.shared.setUserProperty(key: "Notification Permission", value: notificationStatus)
            }
        }
    }
    
    private func requestNotificationPermission() {
        NotificationDelegate.shared.requestNotificationPermissions()
        
        // Check status after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkNotificationStatus()
        }
    }
    
    private func loadDeviceToken() {
        // Try to get device token string from UserDefaults
        if let tokenString = UserDefaults.standard.string(forKey: "deviceTokenString") {
            deviceToken = tokenString
        } else {
            deviceToken = "Not available"
        }
    }
    
    private func saveSettings() {
        isSaving = true
        
        // Update local profile service
        profileService.updateNotificationPreference(type: "push", enabled: pushNotifications)
        profileService.updateNotificationPreference(type: "email", enabled: emailNotifications)
        profileService.updateNotificationPreference(type: "sms", enabled: smsNotifications)
        
        // Update CleverTap preferences
        CleverTapService.shared.updateEngagementProfile(
            pushOptIn: pushNotifications,
            emailOptIn: emailNotifications
        )
        CleverTapService.shared.setPushDND(enabled: !pushNotifications)
        CleverTapService.shared.setEmailDND(enabled: !emailNotifications)
        CleverTapService.shared.setSMSDND(enabled: !smsNotifications)
        if emailNotifications {
            CleverTapService.shared.setEmailAddressDND(enabled: false)
        }
        if smsNotifications {
            CleverTapService.shared.setPhoneDND(enabled: false)
        }
        
        // Track detailed preferences
        CleverTapService.shared.setUserProperty(key: "Order Updates Enabled", value: orderUpdates)
        CleverTapService.shared.setUserProperty(key: "Marketing Emails Enabled", value: marketingEmails)
        CleverTapService.shared.setUserProperty(key: "Weekly Digest Enabled", value: weeklyDigest)
        CleverTapService.shared.setUserProperty(key: "Promotional SMS Enabled", value: promotionalSMS)
        CleverTapService.shared.setUserProperty(key: "InApp Notifications Enabled", value: inAppNotifications)
        CleverTapService.shared.setUserProperty(key: "Group Similar Notifications", value: groupSimilarNotifications)

        UserDefaults.standard.set(groupSimilarNotifications, forKey: "notifications.groupSimilar")
        
        // Track settings update event
        CleverTapService.shared.setUserProperty(key: "Notification Settings Updated", value: Date())
        CleverTapService.shared.addToMultiValueProperty(key: "Features Used", value: "Notification Settings")
        _ = profileService.forceCleverTapSync()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            showSuccessAlert = true
        }
    }
}

// MARK: - Supporting Views

struct NotificationToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isEnabled: Bool
    let color: Color
    var onToggle: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
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
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .onChange(of: isEnabled) { _, _ in
                    onToggle?()
                }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

struct StatusRow: View {
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
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

private extension View {
    func settingsSurfaceCard(isDarkMode: Bool) -> some View {
        self
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
            )
    }
}

#Preview {
    NotificationSettingsView()
} 
