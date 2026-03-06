import SwiftUI
import CleverTapSDK
import UserNotifications
import FirebaseAuth

struct CleverTapTestView: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var testHistory: [TestEvent] = []
    @State private var isRefreshingDebug = false
    @State private var animateAmbientBackground = false
    @State private var revealContent = false
    @Environment(\.colorScheme) var colorScheme

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var stablePrimaryText: Color {
        isDarkMode ? Color.white.opacity(0.93) : Color.black.opacity(0.90)
    }

    private var stableSecondaryText: Color {
        isDarkMode ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
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
            Color("CleverTapPrimary").opacity(0.20),
            Color("CleverTapSecondary").opacity(0.10),
            Color(.systemBackground),
            Color(.systemBackground)
        ]
    }

    private var cleverTapSDKVersion: String {
        CleverTapService.shared.sdkVersionString()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private var cleverTapProfileId: String {
        CleverTap.sharedInstance()?.profileGetID() ?? "Not Available"
    }

    private var isUserAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }

    private var cleverTapIdentity: String {
        guard isUserAuthenticated else { return "Not Set" }
        let identity = CleverTap.sharedInstance()?.profileGet("Identity") as? String ?? ""
        return identity.isEmpty ? "Not Set" : identity
    }

    private var cleverTapEmail: String {
        guard isUserAuthenticated else { return "Not Set" }
        let email = CleverTap.sharedInstance()?.profileGet("Email") as? String ?? ""
        return email.isEmpty ? "Not Set" : email
    }

    private var profileStatus: String {
        guard isUserAuthenticated else { return "Signed Out" }
        let isIdentified = cleverTapIdentity != "Not Set" || cleverTapEmail != "Not Set"
        return isIdentified ? "Identified" : "Anonymous"
    }

    private var deviceTokenStatus: String {
        let localToken = UserDefaults.standard.string(forKey: "deviceTokenString") ?? ""
        let profileToken = CleverTap.sharedInstance()?.profileGet("Device Token") as? String ?? ""

        switch (localToken.isEmpty, profileToken.isEmpty) {
        case (false, false): return "Synced"
        case (false, true): return "Local only"
        case (true, false): return "Profile only"
        case (true, true): return "Missing"
        }
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

    private var appInboxStatus: String {
        inAppService.appInboxCount > 0 ? "Active (\(inAppService.appInboxCount))" : "Empty"
    }
    
    struct TestEvent: Identifiable {
        let id = UUID()
        let title: String
        let timestamp: Date
        let success: Bool
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(
                    x: animateAmbientBackground ? -130 : -165,
                    y: animateAmbientBackground ? -335 : -365
                )

            Circle()
                .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 44)
                .offset(
                    x: animateAmbientBackground ? 150 : 180,
                    y: animateAmbientBackground ? -300 : -265
                )

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .frame(maxWidth: .infinity)

                    testingModelSection
                        .frame(maxWidth: .infinity)

                    statsSection
                        .frame(maxWidth: .infinity)

                    inAppNotificationSection
                        .frame(maxWidth: .infinity)

                    pushNotificationSection
                        .frame(maxWidth: .infinity)

                    appInboxSection
                        .frame(maxWidth: .infinity)

                    otherFeaturesSection
                        .frame(maxWidth: .infinity)

                    debugSection
                        .frame(maxWidth: .infinity)

                    if !inAppService.receivedNotifications.isEmpty {
                        recentActivitySection
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 100)
                .frame(maxWidth: .infinity)
                .opacity(revealContent ? 1 : 0)
                .offset(y: revealContent ? 0 : 8)
                .animation(.easeInOut(duration: 0.30), value: revealContent)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") { }
        }
        .onAppear {
            refreshDebugInfo()
            if !revealContent {
                revealContent = true
            }
            if !animateAmbientBackground {
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    animateAmbientBackground = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CLEVERTAP TEST STUDIO")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.14), in: Capsule())

                    Text("CleverTap Test Lab")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(stablePrimaryText)

                    Text("Validate push, in-app, inbox, profile and native display journeys from one premium console.")
                        .font(.subheadline)
                        .foregroundColor(stableSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.28 : 0.18))
                        .frame(width: 64, height: 64)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            HStack(spacing: 8) {
                StudioPill(title: "In-App", value: "\(inAppService.inAppNotificationCount)", icon: "bell.badge")
                StudioPill(title: "Push", value: "\(inAppService.pushNotificationCount)", icon: "paperplane.fill")
                StudioPill(title: "Inbox", value: "\(inAppService.appInboxCount)", icon: "tray.fill")
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.22 : 0.08), radius: 14, x: 0, y: 10)
    }

    // MARK: - Behavior Guide
    private var testingModelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How Test Lab Works")
                .font(.headline)

            Text("Most buttons emit CleverTap trigger events. They do not directly render push or in-app by themselves.")
                .font(.subheadline)
                .foregroundColor(stableSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text("Campaign UI appears only when dashboard campaign conditions and user targeting are satisfied.")
                .font(.subheadline)
                .foregroundColor(stableSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text("Local-only actions: Push permission, Inbox refresh, diagnostics refresh.")
                .font(.subheadline)
                .foregroundColor(stableSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .testLabSectionCard(cornerRadius: 18)
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
        .testLabSectionCard()
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
                        .foregroundColor(stableSecondaryText)
                    Spacer()
                    Text(inAppService.pushPermissionStatus)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stablePrimaryText)
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
        .testLabSectionCard()
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
                        .foregroundColor(stableSecondaryText)
                    Spacer()
                    Text("\(inAppService.appInboxCount) messages")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stablePrimaryText)
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

                // Row 2: Carousel Inbox Trigger
                TestActionCard(
                    title: "Carousel Inbox",
                    subtitle: "Trigger carousel inbox campaign",
                    icon: "square.stack.3d.forward.dottedline",
                    gradient: [Color.orange, Color.pink],
                    action: { inAppService.triggerCarouselAppInboxMessage() },
                    isWide: true
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .testLabSectionCard()
    }
    
    // MARK: - Other Features Section
    private var otherFeaturesSection: some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "🛠 Testing Tools",
                subtitle: "Additional testing and debugging tools"
            )

            testingToolsInfoCard
            
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
                    action: triggerReminderTest,
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
        .testLabSectionCard()
    }

    private var testingToolsInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What These Tools Do")
                .font(.subheadline.weight(.semibold))

            Text("Force Sync: Queues `Force_InApp_Sync` event and resumes queued in-app notifications. It does not bypass campaign conditions.")
                .font(.caption)
                .foregroundColor(stableSecondaryText)

            Text("Custom Event: Sends `Custom_Test_Event` with random test number and timestamp.")
                .font(.caption)
                .foregroundColor(stableSecondaryText)

            Text("Reminder Test: Sends reminder test event with due date set to ~5 minutes ahead.")
                .font(.caption)
                .foregroundColor(stableSecondaryText)

            Text("Update Profile: Pushes debug profile fields (`last_test`, `test_user`) to CleverTap profile.")
                .font(.caption)
                .foregroundColor(stableSecondaryText)

            Text("Status Check: Refreshes SDK diagnostics (ID, token, push permission, inbox count).")
                .font(.caption)
                .foregroundColor(stableSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Debug Section
    private var debugSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                SectionHeader(
                    title: "🔧 Debug Information",
                    subtitle: "SDK health, identity, push and inbox diagnostics"
                )

                Button {
                    refreshDebugInfo()
                } label: {
                    HStack(spacing: 6) {
                        if isRefreshingDebug {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isRefreshingDebug)
            }
            
            VStack(spacing: 12) {
                debugInfoGroupCard(title: "SDK & Config") {
                    DebugInfoRow(
                        title: "Connection",
                        value: inAppService.connectionStatus,
                        icon: "network",
                        status: debugStatusForConnection(inAppService.connectionStatus)
                    )

                    DebugInfoRow(
                        title: "SDK Initialized",
                        value: inAppService.isSDKInitialized ? "Yes" : "No",
                        icon: "bolt.horizontal.circle",
                        status: inAppService.isSDKInitialized ? .good : .bad
                    )

                    DebugInfoRow(
                        title: "SDK Version",
                        value: cleverTapSDKVersion,
                        icon: "gear"
                    )

                    DebugInfoRow(
                        title: "Account ID",
                        value: cleverTapAccountId,
                        icon: "number",
                        status: cleverTapAccountId == "Not Found" ? .bad : .good
                    )

                    DebugInfoRow(
                        title: "Region",
                        value: cleverTapRegion,
                        icon: "globe.asia.australia"
                    )

                    DebugInfoRow(
                        title: "Config Token",
                        value: cleverTapTokenStatus,
                        icon: "key",
                        status: cleverTapTokenStatus == "Configured" ? .good : .bad
                    )
                }

                debugInfoGroupCard(title: "Identity") {
                    DebugInfoRow(
                        title: "Profile State",
                        value: profileStatus,
                        icon: "person.crop.circle",
                        status: profileStatus == "Identified" ? .good : .warn
                    )

                    DebugInfoRow(
                        title: "CleverTap ID",
                        value: cleverTapProfileId,
                        icon: "tag"
                    )

                    DebugInfoRow(
                        title: "Identity",
                        value: cleverTapIdentity,
                        icon: "person.text.rectangle",
                        status: cleverTapIdentity == "Not Set" ? .warn : .good
                    )

                    DebugInfoRow(
                        title: "Email",
                        value: cleverTapEmail,
                        icon: "envelope",
                        status: cleverTapEmail == "Not Set" ? .warn : .good
                    )
                }

                debugInfoGroupCard(title: "Push & Inbox") {
                    DebugInfoRow(
                        title: "Push Permissions",
                        value: inAppService.pushPermissionStatus,
                        icon: "bell.badge",
                        status: debugStatusForPushPermission(inAppService.pushPermissionStatus)
                    )

                    DebugInfoRow(
                        title: "Device Token",
                        value: deviceTokenStatus,
                        icon: "iphone.gen3.badge.exclamationmark",
                        status: debugStatusForDeviceToken(deviceTokenStatus)
                    )

                    DebugInfoRow(
                        title: "App Inbox Status",
                        value: appInboxStatus,
                        icon: "tray",
                        status: debugStatusForInbox(appInboxStatus)
                    )

                    DebugInfoRow(
                        title: "Last Refresh",
                        value: lastDiagnosticsRefreshText,
                        icon: "clock"
                    )
                }

                debugInfoGroupCard(title: "App") {
                    DebugInfoRow(
                        title: "App Version",
                        value: "\(appVersion) (\(appBuild))",
                        icon: "app.badge"
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .testLabSectionCard()
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
        .testLabSectionCard()
    }

    // MARK: - Action Methods
    private func forceSyncNotifications() {
        let didSync = inAppService.forceSyncInAppNotifications()
        addTestEvent(title: "Force Sync", success: didSync)

        if didSync {
            showAlert(message: "Force sync triggered. If campaign trigger conditions are met, in-app should display on next eligible event.")
        } else {
            showAlert(message: "Force sync failed: CleverTap SDK is not initialized yet.")
        }
    }
    
    private func triggerCustomEvent() {
        guard let sdk = CleverTap.sharedInstance() else {
            addTestEvent(title: "Custom Event Sent", success: false)
            showAlert(message: "Custom event failed: CleverTap SDK is not initialized.")
            return
        }

        sdk.recordEvent("Custom_Test_Event", withProps: [
            "test_number": Int.random(in: 1...1000),
            "timestamp": Date().timeIntervalSince1970
        ])
        
        addTestEvent(title: "Custom Event Sent", success: true)
        showAlert(message: "Custom event queued successfully.")
    }

    private func triggerReminderTest() {
        let didTrigger = CleverTapService.shared.fireReminderTestEvent(reminderId: "test_001")
        addTestEvent(title: "Reminder Test Triggered", success: didTrigger)

        if didTrigger {
            showAlert(message: "Reminder test event queued. Campaign should evaluate due_date in ~5 minutes.")
        } else {
            showAlert(message: "Reminder test failed: CleverTap SDK is not initialized.")
        }
    }
    
    private func updateUserProfile() {
        guard let sdk = CleverTap.sharedInstance() else {
            addTestEvent(title: "Profile Updated", success: false)
            showAlert(message: "Profile update failed: CleverTap SDK is not initialized.")
            return
        }

        sdk.profilePush([
            "last_test": Date().timeIntervalSince1970,
            "test_user": true
        ])
        
        addTestEvent(title: "Profile Updated", success: true)
        showAlert(message: "Profile debug properties queued successfully.")
    }
    
    private func checkCleverTapStatus() {
        refreshDebugInfo(showToast: true)
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

    private func refreshDebugInfo(showToast: Bool = false) {
        guard !isRefreshingDebug else { return }
        isRefreshingDebug = true
        inAppService.refreshDiagnostics()

        // Allow async notification-permission / inbox refresh callbacks to settle.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isRefreshingDebug = false
            let sdkReady = inAppService.isSDKInitialized
            addTestEvent(title: "Diagnostics Refreshed", success: sdkReady)

            if showToast {
                if sdkReady {
                    showAlert(message: "SDK: Ready ✅\n\(inAppService.statusSummary())")
                } else {
                    showAlert(message: "CleverTap SDK is not initialized. Check AppDelegate setup and account credentials.")
                }
            }
        }
    }

    private func debugStatusForConnection(_ value: String) -> DebugInfoRow.DebugStatus {
        if value.lowercased().contains("anonymous") { return .warn }
        if value.lowercased().contains("identified") { return .good }
        if value.lowercased().contains("not initialized") { return .bad }
        return .warn
    }

    private func debugStatusForPushPermission(_ value: String) -> DebugInfoRow.DebugStatus {
        let normalized = value.lowercased()
        if normalized.contains("authorized") || normalized.contains("provisional") { return .good }
        if normalized.contains("not determined") { return .warn }
        return .bad
    }

    private func debugStatusForDeviceToken(_ value: String) -> DebugInfoRow.DebugStatus {
        switch value {
        case "Synced": return .good
        case "Local only", "Profile only": return .warn
        default: return .bad
        }
    }

    private func debugStatusForInbox(_ value: String) -> DebugInfoRow.DebugStatus {
        value.lowercased().contains("active") ? .good : .warn
    }

    @ViewBuilder
    private func debugInfoGroupCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(stableSecondaryText)
                .textCase(.uppercase)

            content()
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.93) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StudioPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(title): \(value)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundColor(secondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
    }
}

struct StatCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String
    let icon: String
    let color: Color

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.93) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: 11))

            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(primaryText)

            Text(title)
                .font(.caption2)
                .foregroundColor(secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}

struct TestActionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    var isWide: Bool = false

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.93) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)

                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryText)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 10)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(ScalePressButtonStyle())
    }
}

struct DebugInfoRow: View {
    @Environment(\.colorScheme) private var colorScheme

    enum DebugStatus {
        case good
        case warn
        case bad

        var label: String {
            switch self {
            case .good: return "OK"
            case .warn: return "WARN"
            case .bad: return "FAIL"
            }
        }

        var color: Color {
            switch self {
            case .good: return .green
            case .warn: return .orange
            case .bad: return .red
            }
        }
    }

    let title: String
    let value: String
    let icon: String
    var status: DebugStatus? = nil

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.93) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(secondaryText)
            
            Spacer()

            if let status {
                Text(status.label)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.15), in: Capsule())
            }
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(primaryText)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct NotificationLogRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let notification: CleverTapInAppService.InAppNotificationLog

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.93) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.74) : Color.black.opacity(0.62)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(notification.status.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.eventName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(primaryText)
                
                Text(notification.status.displayText)
                    .font(.caption2)
                    .foregroundColor(secondaryText)
            }
            
            Spacer()
            
            Text(formatTime(notification.timestamp))
                .font(.caption2)
                .foregroundColor(secondaryText)
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

struct NativeDisplayImplementationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .foregroundColor(.indigo)
                Text("How to use from CleverTap Dashboard")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 6) {
                guideRow("Create a Native Display campaign in CleverTap and publish it.")
                guideRow("In campaign payload custom extras, pass location key like `home_hero`, `product_list_header`, `cart_recommendations`, `profile_offers`.")
                guideRow("Send/trigger campaign to test users, then tap `Refresh Units` in Test Lab.")
                guideRow("Verify status card locations and open `View All Display Units` for full payload preview.")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Rendered in app at:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Text("Home • Product List • Cart • Profile")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.indigo.opacity(0.25), lineWidth: 1)
        )
    }

    private func guideRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.indigo)
                .padding(.top, 6)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

private struct TestLabSectionCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
}

private extension View {
    func testLabSectionCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(TestLabSectionCardModifier(cornerRadius: cornerRadius))
    }
}

#Preview {
    CleverTapTestView()
} 
