import SwiftUI
import CleverTapSDK
import UserNotifications

struct CleverTapTestView: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var testHistory: [TestEvent] = []
    @Environment(\.colorScheme) var colorScheme

    private var cleverTapSDKVersion: String {
        CleverTapService.shared.sdkVersionString()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private var profileStatus: String {
        let profileID = CleverTap.sharedInstance()?.profileGetID() ?? ""
        return profileID.isEmpty ? "Anonymous / Not Logged In" : "Identified"
    }

    private var deviceTokenStatus: String {
        let token = CleverTap.sharedInstance()?.profileGet("Device Token")
        if let tokenString = token as? String, !tokenString.isEmpty {
            return "Present"
        }
        return "Not Available"
    }

    private var cleverTapAccountId: String {
        CleverTapService.shared.accountIdString()
    }

    private var cleverTapRegion: String {
        CleverTapService.shared.regionString()
    }

    private var cleverTapTokenStatus: String {
        CleverTapService.shared.tokenStatusString()
    }

    private var lastDiagnosticsRefreshText: String {
        guard let date = inAppService.lastDiagnosticsRefresh else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private let nativeDisplayLocations = [
        "home_hero",
        "product_list_header", 
        "cart_recommendations",
        "profile_offers",
        "product_detail_related"
    ]
    
    struct TestEvent: Identifiable {
        let id = UUID()
        let title: String
        let timestamp: Date
        let success: Bool
    }
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.1),
                    Color("CleverTapSecondary").opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Brain Icon
                    headerSection
                    
                    // Stats Dashboard
                    statsSection
                    
                    // In-App Notification Testing - All Categories
                    inAppNotificationSection
                    
                    // Push Notifications
                    pushNotificationSection
                    
                    // App Inbox
                    appInboxSection
                    
                    // Other Testing Features
                    otherFeaturesSection
                    
                    // Debug Information
                    debugSection

                    // Recent Activity
                    if !inAppService.receivedNotifications.isEmpty {
                        recentActivitySection
                    }
                    
                    // Native Display Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Native Display",
                            subtitle: "Test dynamic content display"
                        )
                        
                        VStack(spacing: 12) {
                            // Display Units Status
                            NativeDisplayStatusCard()
                            
                            // Test Native Display Events
                            VStack(spacing: 8) {
                                ForEach(nativeDisplayLocations, id: \.self) { location in
                                    TestActionCard(
                                        title: "Test \(location.capitalized)",
                                        subtitle: "Trigger display test",
                                        icon: "rectangle.badge.plus",
                                        gradient: [Color.purple, Color.blue],
                                        action: { 
                                            CleverTapNativeDisplayService.shared.triggerTestEvent(for: location)
                                            addTestEvent(title: "Native Display Test: \(location)", success: true)
                                        }
                                    )
                                }
                            }
                            
                            // Refresh Display Units
                            TestActionCard(
                                title: "Refresh Units",
                                subtitle: "Update display units",
                                icon: "arrow.clockwise",
                                gradient: [Color.blue, Color.cyan],
                                action: { 
                                    CleverTapNativeDisplayService.shared.refreshDisplayUnits()
                                    addTestEvent(title: "Display Units Refreshed", success: true)
                                }
                            )
                            
                            // Show All Display Units
                            NavigationLink(destination: NativeDisplayDebugView()) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                        .foregroundColor(.green)
                                    Text("View All Display Units")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("CleverTap Test Lab")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") { }
        }
        .onAppear {
            inAppService.refreshDiagnostics()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Brain Icon with Glow Effect
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
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("CleverTap Testing Lab")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Test your in-app notifications and analytics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "In-App",
                value: "\(inAppService.inAppNotificationCount)",
                icon: "bell.badge",
                color: .blue
            )
            
            StatCard(
                title: "Push",
                value: "\(inAppService.pushNotificationCount)",
                icon: "paperplane.fill",
                color: .green
            )
            
            StatCard(
                title: "Inbox",
                value: "\(inAppService.appInboxCount)",
                icon: "tray.fill",
                color: .orange
            )
            
            StatCard(
                title: "Status",
                value: inAppService.isSDKInitialized ? "✓" : "✗",
                icon: "wifi",
                color: inAppService.isSDKInitialized ? .green : .red
            )
        }
    }
    
    // MARK: - In-App Notification Section
    private var inAppNotificationSection: some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "📱 In-App Notifications",
                subtitle: "Test different notification templates"
            )
            
            VStack(spacing: 16) {
                // Row 1: Cover & Interstitial
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Cover",
                        subtitle: "Full screen overlay",
                        icon: "rectangle.stack.fill",
                        gradient: [Color.blue, Color.purple],
                        action: { inAppService.triggerCoverInApp() }
                    )
                    
                    TestActionCard(
                        title: "Interstitial",
                        subtitle: "Modal popup",
                        icon: "square.stack.3d.up",
                        gradient: [Color.purple, Color.pink],
                        action: { inAppService.triggerInterstitialInApp() }
                    )
                }
                
                // Row 2: Half-Interstitial & Header
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Half-Interstitial",
                        subtitle: "Half screen modal",
                        icon: "rectangle.split.2x1",
                        gradient: [Color.pink, Color.orange],
                        action: { inAppService.triggerHalfInterstitialInApp() }
                    )
                    
                    TestActionCard(
                        title: "Header",
                        subtitle: "Top banner",
                        icon: "rectangle.topthird.inset",
                        gradient: [Color.orange, Color.yellow],
                        action: { inAppService.triggerHeaderInApp() }
                    )
                }
                
                // Row 3: Footer & Alert
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Footer",
                        subtitle: "Bottom banner",
                        icon: "rectangle.bottomthird.inset.filled",
                        gradient: [Color.yellow, Color.green],
                        action: { inAppService.triggerFooterInApp() }
                    )
                    
                    TestActionCard(
                        title: "Alert",
                        subtitle: "System alert",
                        icon: "exclamationmark.triangle.fill",
                        gradient: [Color.green, Color.cyan],
                        action: { inAppService.triggerAlertInApp() }
                    )
                }
                
                // Row 4: Banner & Custom HTML
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Banner",
                        subtitle: "Banner notification",
                        icon: "flag.fill",
                        gradient: [Color.cyan, Color.blue],
                        action: { inAppService.triggerBannerInApp() }
                    )
                    
                    TestActionCard(
                        title: "Custom HTML",
                        subtitle: "HTML content",
                        icon: "chevron.left.forwardslash.chevron.right",
                        gradient: [Color.indigo, Color.purple],
                        action: { inAppService.triggerCustomHTMLInApp() }
                    )
                }
                
                // Row 5: WebView & Rating
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "WebView",
                        subtitle: "Web content",
                        icon: "globe",
                        gradient: [Color.teal, Color.mint],
                        action: { inAppService.triggerWebViewInApp() }
                    )
                    
                    TestActionCard(
                        title: "Rating",
                        subtitle: "Star rating",
                        icon: "star.fill",
                        gradient: [Color.mint, Color.green],
                        action: { inAppService.triggerRatingInApp() }
                    )
                }
                
                // Row 6: Survey & Carousel
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Survey",
                        subtitle: "Question form",
                        icon: "list.bullet.clipboard",
                        gradient: [Color.brown, Color.orange],
                        action: { inAppService.triggerSurveyInApp() }
                    )
                    
                    TestActionCard(
                        title: "Carousel",
                        subtitle: "Swipeable cards",
                        icon: "square.stack.3d.forward.dottedline",
                        gradient: [Color.red, Color.pink],
                        action: { inAppService.triggerCarouselInApp() }
                    )
                }
                
                // Row 7: Gamification - Scratch Card & Spin The Wheel
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Scratch Card",
                        subtitle: "Reveal and win",
                        icon: "scribble.variable",
                        gradient: [Color.green, Color.teal],
                        action: { inAppService.triggerScratchCardInApp() }
                    )
                    
                    TestActionCard(
                        title: "Spin The Wheel",
                        subtitle: "Try your luck",
                        icon: "circle.grid.3x3.fill",
                        gradient: [Color.teal, Color.blue],
                        action: { inAppService.triggerSpinTheWheelInApp() }
                    )
                }
                
                // Row 8: Basic Template (Wide)
                TestActionCard(
                    title: "Basic Template",
                    subtitle: "Standard notification template",
                    icon: "app.badge",
                    gradient: [Color.gray, Color.secondary],
                    action: { inAppService.triggerBasicInApp() },
                    isWide: true
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Push Notification Section
    private var pushNotificationSection: some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "📤 Push Notifications",
                subtitle: "Test push notification functionality"
            )
            
            VStack(spacing: 16) {
                // Push Permission Status
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundColor(.blue)
                    Text("Permission Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(inAppService.pushPermissionStatus)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                
                // Row 1: Permission & Basic Push
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Request Permission",
                        subtitle: "Ask for push access",
                        icon: "bell.badge.fill",
                        gradient: [Color.blue, Color.purple],
                        action: { inAppService.requestPushPermission() }
                    )
                    
                    TestActionCard(
                        title: "Basic Push",
                        subtitle: "Simple notification",
                        icon: "paperplane.fill",
                        gradient: [Color.purple, Color.pink],
                        action: { inAppService.triggerPushNotification() }
                    )
                }
                
                // Row 2: Rich Push & Carousel Push
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Rich Push",
                        subtitle: "With media & actions",
                        icon: "photo.fill",
                        gradient: [Color.pink, Color.orange],
                        action: { inAppService.triggerRichPushNotification() }
                    )
                    
                    TestActionCard(
                        title: "Carousel Push",
                        subtitle: "Multiple images",
                        icon: "square.stack.3d.forward.dottedline",
                        gradient: [Color.orange, Color.yellow],
                        action: { inAppService.triggerCarouselPush() }
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - App Inbox Section
    private var appInboxSection: some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "📫 App Inbox",
                subtitle: "Manage in-app messages"
            )
            
            VStack(spacing: 16) {
                // Inbox Status
                HStack {
                    Image(systemName: "tray.fill")
                        .foregroundColor(.orange)
                    Text("Messages:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(inAppService.appInboxCount) messages")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                
                // Row 1: Trigger & Refresh
                HStack(spacing: 16) {
                    TestActionCard(
                        title: "Trigger Message",
                        subtitle: "Send inbox message",
                        icon: "envelope.fill",
                        gradient: [Color.orange, Color.red],
                        action: { inAppService.triggerAppInboxMessage() }
                    )
                    
                    TestActionCard(
                        title: "Refresh Inbox",
                        subtitle: "Update message list",
                        icon: "arrow.clockwise",
                        gradient: [Color.green, Color.teal],
                        action: { inAppService.refreshAppInbox() }
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Other Features Section
    private var otherFeaturesSection: some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "🛠 Testing Tools",
                subtitle: "Additional testing and debugging tools"
            )
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TestActionCard(
                        title: "Force Sync",
                        subtitle: "Manual sync",
                        icon: "arrow.triangle.2.circlepath",
                        gradient: [Color.indigo, Color.purple],
                        action: forceSyncNotifications
                    )
                    
                    TestActionCard(
                        title: "Custom Event",
                        subtitle: "Send test event",
                        icon: "star.fill",
                        gradient: [Color.mint, Color.green],
                        action: triggerCustomEvent
                    )
                }
                
                TestActionCard(
                    title: "Reminder Test",
                    subtitle: "Fire reminder event (5 min)",
                    icon: "clock.badge",
                    gradient: [Color.purple, Color.indigo],
                    action: {
                        CleverTapService.shared.fireReminderTestEvent(reminderId: "test_001")
                        addTestEvent(title: "Reminder Test Triggered", success: true)
                        showAlert(message: "Reminder test event scheduled for ~5 minutes from now.")
                    },
                    isWide: true
                )
                
                HStack(spacing: 12) {
                    TestActionCard(
                        title: "Update Profile",
                        subtitle: "User data test",
                        icon: "person.crop.circle",
                        gradient: [Color.brown, Color.orange],
                        action: updateUserProfile
                    )
                    
                    TestActionCard(
                        title: "Status Check",
                        subtitle: "Verify setup",
                        icon: "checkmark.shield",
                        gradient: [Color.teal, Color.cyan],
                        action: checkCleverTapStatus
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                SectionHeader(
                    title: "🔧 Debug Information",
                    subtitle: "System status and configuration"
                )

                Button {
                    inAppService.refreshDiagnostics()
                    addTestEvent(title: "Diagnostics Refreshed", success: true)
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 12) {
                DebugInfoRow(
                    title: "CleverTap ID",
                    value: CleverTap.sharedInstance()?.profileGetID() ?? "Not Available",
                    icon: "tag"
                )
                
                DebugInfoRow(
                    title: "Connection Status",
                    value: inAppService.connectionStatus,
                    icon: "network"
                )
                
                DebugInfoRow(
                    title: "Push Permissions",
                    value: inAppService.pushPermissionStatus,
                    icon: "bell.badge"
                )
                
                DebugInfoRow(
                    title: "SDK Version",
                    value: cleverTapSDKVersion,
                    icon: "gear"
                )

                DebugInfoRow(
                    title: "SDK Initialized",
                    value: inAppService.isSDKInitialized ? "Yes" : "No",
                    icon: "bolt.horizontal.circle"
                )

                DebugInfoRow(
                    title: "Account ID",
                    value: cleverTapAccountId,
                    icon: "number"
                )

                DebugInfoRow(
                    title: "Region",
                    value: cleverTapRegion,
                    icon: "globe.asia.australia"
                )

                DebugInfoRow(
                    title: "Token",
                    value: cleverTapTokenStatus,
                    icon: "key"
                )

                DebugInfoRow(
                    title: "Last Refresh",
                    value: lastDiagnosticsRefreshText,
                    icon: "clock"
                )

                DebugInfoRow(
                    title: "Profile State",
                    value: profileStatus,
                    icon: "person.crop.circle"
                )

                DebugInfoRow(
                    title: "Device Token",
                    value: deviceTokenStatus,
                    icon: "iphone.gen3.badge.exclamationmark"
                )

                DebugInfoRow(
                    title: "App Inbox Status",
                    value: inAppService.appInboxCount > 0 ? "Active (\(inAppService.appInboxCount))" : "Empty",
                    icon: "tray"
                )

                DebugInfoRow(
                    title: "App Version",
                    value: "\(appVersion) (\(appBuild))",
                    icon: "app.badge"
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                SectionHeader(
                    title: "📋 Recent Activity",
                    subtitle: "Latest notification events"
                )
                
                Spacer()
                
                Button("Clear") {
                    inAppService.clearInAppHistory()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
            
            LazyVStack(spacing: 8) {
                ForEach(inAppService.receivedNotifications.prefix(5)) { notification in
                    NotificationLogRow(notification: notification)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Action Methods
    private func forceSyncNotifications() {
        inAppService.forceSyncInAppNotifications()
        inAppService.resumeInAppNotifications()
        addTestEvent(title: "Force Sync", success: true)
        showAlert(message: "Notifications synced!")
    }
    
    private func triggerCustomEvent() {
        CleverTap.sharedInstance()?.recordEvent("Custom_Test_Event", withProps: [
            "test_number": Int.random(in: 1...1000),
            "timestamp": Date().timeIntervalSince1970
        ])
        
        addTestEvent(title: "Custom Event Sent", success: true)
        showAlert(message: "Custom event sent successfully!")
    }
    
    private func updateUserProfile() {
        CleverTap.sharedInstance()?.profilePush([
            "last_test": Date().timeIntervalSince1970,
            "test_user": true
        ])
        
        addTestEvent(title: "Profile Updated", success: true)
        showAlert(message: "Profile updated successfully!")
    }
    
    private func checkCleverTapStatus() {
        inAppService.refreshDiagnostics()
        let sdkReady = inAppService.isSDKInitialized
        addTestEvent(title: "Status Check", success: sdkReady)

        if sdkReady {
            showAlert(message: "SDK: Ready ✅\n\(inAppService.statusSummary())")
        } else {
            showAlert(message: "CleverTap SDK is not initialized. Check AppDelegate setup and account credentials.")
        }
    }

    // MARK: - Helper Methods
    private func addTestEvent(title: String, success: Bool) {
        let event = TestEvent(
            title: title,
            timestamp: Date(),
            success: success
        )
        testHistory.insert(event, at: 0)
        
        if testHistory.count > 50 {
            testHistory.removeLast()
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TestActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    var isWide: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct DebugInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct NotificationLogRow: View {
    let notification: CleverTapInAppService.InAppNotificationLog
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.status.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.eventName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(notification.status.displayText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatTime(notification.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct NativeDisplayStatusCard: View {
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.3.group.fill")
                    .foregroundColor(.purple)
                Text("Display Units Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if nativeDisplayService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TestStatusRow(
                    title: "Total Units",
                    value: "\(nativeDisplayService.displayUnits.count)",
                    color: .blue
                )
                
                TestStatusRow(
                    title: "Available Locations",
                    value: "\(nativeDisplayService.getAvailableLocations().count)",
                    color: .green
                )
                
                if let lastUpdated = nativeDisplayService.lastUpdated {
                    TestStatusRow(
                        title: "Last Updated",
                        value: formatDate(lastUpdated),
                        color: .orange
                    )
                }
                
                if !nativeDisplayService.getAvailableLocations().isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Locations:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(nativeDisplayService.getAvailableLocations(), id: \.self) { location in
                                    Text(location)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TestStatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct NativeDisplayDebugView: View {
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    
                    Text("Native Display Units")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(nativeDisplayService.displayUnits.count) units available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Display Units
                if nativeDisplayService.displayUnits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.dashed")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Display Units")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Create native display campaigns in CleverTap dashboard to see them here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            nativeDisplayService.refreshDisplayUnits()
                        }) {
                            Text("Refresh")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.purple, in: RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .padding(40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(nativeDisplayService.displayUnits.enumerated()), id: \.offset) { index, unit in
                            VStack(spacing: 16) {
                                // Unit Details
                                NativeDisplayUnitCard(unit: unit, index: index)
                                
                                // Actual Display Preview
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Preview:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    NativeDisplayView(displayUnit: unit)
                                }
                            }
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationTitle("Display Units")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    nativeDisplayService.refreshDisplayUnits()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

struct NativeDisplayUnitCard: View {
    let unit: CleverTapDisplayUnit
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            propertiesSection
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var headerSection: some View {
        HStack {
            Text("Unit \(index + 1)")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if let unitID = unit.unitID {
                Text("ID: \(unitID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let type = unit.type {
                PropertyRow(label: "Type", value: type)
            }
            
            backgroundColorSection
            
            PropertyRow(label: "Contents", value: "\(unit.contents?.count ?? 0)")
            
            customExtrasSection
            
            contentDetailsSection
        }
    }
    
    @ViewBuilder
    private var backgroundColorSection: some View {
        if let bgColor = unit.bgColor {
            HStack {
                Text("Background:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: bgColor))
                        .frame(width: 12, height: 12)
                    Text(bgColor)
                        .font(.caption)
                        .monospaced()
                }
            }
        }
    }
    
    @ViewBuilder
    private var customExtrasSection: some View {
        if let customExtras = unit.customExtras, !customExtras.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Extras:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(Array(customExtras.keys).compactMap { $0 as? String }.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(customExtras[key] ?? "")")
                            .font(.caption2)
                            .monospaced()
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentDetailsSection: some View {
        if let contents = unit.contents, !contents.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Content Details:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(Array(contents.enumerated()), id: \.offset) { contentIndex, content in
                    ContentDetailCard(content: content, index: contentIndex)
                }
            }
        }
    }
}

struct ContentDetailCard: View {
    let content: CleverTapDisplayUnitContent
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Content \(index + 1)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            contentProperties
            
            mediaTypeBadges
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private var contentProperties: some View {
        if let title = content.title, !title.isEmpty {
            PropertyRow(label: "Title", value: title)
        }
        
        if let message = content.message, !message.isEmpty {
            PropertyRow(label: "Message", value: message)
        }
        
        if let mediaUrl = content.mediaUrl, !mediaUrl.isEmpty {
            PropertyRow(label: "Media", value: mediaUrl)
        }
        
        if let actionUrl = content.actionUrl, !actionUrl.isEmpty {
            PropertyRow(label: "Action", value: actionUrl)
        }
    }
    
    private var mediaTypeBadges: some View {
        HStack(spacing: 4) {
            if content.mediaIsImage {
                MediaTypeBadge(type: "Image", color: .green)
            }
            if content.mediaIsVideo {
                MediaTypeBadge(type: "Video", color: .red)
            }
            if content.mediaIsAudio {
                MediaTypeBadge(type: "Audio", color: .blue)
            }
            if content.mediaIsGif {
                MediaTypeBadge(type: "GIF", color: .orange)
            }
        }
    }
}

struct PropertyRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .monospaced()
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

struct MediaTypeBadge: View {
    let type: String
    let color: Color
    
    var body: some View {
        Text(type)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color, in: RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    CleverTapTestView()
} 
