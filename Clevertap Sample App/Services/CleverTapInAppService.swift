import Foundation
import CleverTapSDK
import SwiftUI
import Combine
import UserNotifications
import StoreKit

@MainActor
class CleverTapInAppService: ObservableObject {
    static let shared = CleverTapInAppService()
    
    @Published var connectionStatus: String = "Checking..."
    @Published var inAppNotificationCount: Int = 0
    @Published var pushNotificationCount: Int = 0
    @Published var appInboxCount: Int = 0
    @Published var receivedNotifications: [InAppNotificationLog] = []
    @Published var lastPayload: [String: Any] = [:]
    @Published var appInboxMessages: [CleverTapInboxMessage] = []
    @Published var pushPermissionStatus: String = "Unknown"
    @Published var isSDKInitialized: Bool = false
    @Published var lastDiagnosticsRefresh: Date?
    @Published var isRefreshingInbox: Bool = false

    private var connectionMonitorTimer: Timer?
    
    struct InAppNotificationLog: Identifiable {
        let id = UUID()
        let timestamp: Date
        let eventName: String
        let payload: [String: Any]
        let status: NotificationStatus
        
        enum NotificationStatus: String, CaseIterable {
            case triggered = "triggered"
            case displayed = "displayed"
            case dismissed = "dismissed"
            case clicked = "clicked"
            case interacted = "interacted"
            case failed = "failed"
            case pushSent = "push_sent"
            case pushReceived = "push_received"
            case inboxUpdated = "inbox_updated"
            
            var displayText: String {
                switch self {
                case .triggered: return "Triggered"
                case .displayed: return "Displayed"
                case .clicked: return "Clicked"
                case .dismissed: return "Dismissed"
                case .failed: return "Failed"
                case .interacted: return "Interacted"
                case .pushSent: return "Push Sent"
                case .pushReceived: return "Push Received"
                case .inboxUpdated: return "Inbox Updated"
                }
            }
            
            var color: Color {
                switch self {
                case .triggered: return .orange
                case .displayed: return .green
                case .clicked: return .blue
                case .dismissed: return .gray
                case .failed: return .red
                case .interacted: return .purple
                case .pushSent: return .cyan
                case .pushReceived: return .mint
                case .inboxUpdated: return .indigo
                }
            }
        }
    }
    
    private init() {
        checkCleverTapConnection()
        startConnectionMonitoring()
        checkPushPermissions()
        initializeAppInbox()
    }

    deinit {
        connectionMonitorTimer?.invalidate()
    }
    
    private func checkCleverTapConnection() {
        DispatchQueue.main.async {
            let sdk = CleverTap.sharedInstance()
            self.isSDKInitialized = sdk != nil

            guard let sdk else {
                self.connectionStatus = "SDK Not Initialized"
                return
            }

            let cleverTapID = sdk.profileGetID() ?? ""
            let identity = sdk.profileGet("Identity") as? String ?? ""
            let email = sdk.profileGet("Email") as? String ?? ""
            let isIdentifiedUser = !identity.isEmpty || !email.isEmpty

            if isIdentifiedUser {
                self.connectionStatus = "SDK Ready • Identified (\(String(cleverTapID.prefix(8)))...)"
            } else {
                self.connectionStatus = "SDK Ready • Anonymous (\(String(cleverTapID.prefix(8)))...)"
            }
        }
    }
    
    private func startConnectionMonitoring() {
        connectionMonitorTimer?.invalidate()
        connectionMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkCleverTapConnection()
            }
        }
    }
    
    @discardableResult
    func forceSyncInAppNotifications() -> Bool {
        print("🔄 Force syncing in-app notifications...")

        guard let sdk = CleverTap.sharedInstance() else {
            addNotificationLog(
                eventName: "Force Sync Failed",
                payload: ["reason": "sdk_not_initialized"],
                status: .failed
            )
            return false
        }

        let profileID = sdk.profileGetID() ?? "Unknown"
        sdk.recordEvent("Force_InApp_Sync", withProps: [
            "sync_timestamp": Date().timeIntervalSince1970,
            "user_id": profileID
        ])

        // Resume queued in-app notifications as documented by CleverTap.
        sdk.resumeInAppNotifications()

        addNotificationLog(
            eventName: "Force Sync",
            payload: [
                "sync_result": "triggered",
                "user_id": profileID
            ],
            status: .triggered
        )

        refreshDiagnostics()
        print("✅ In-app notification sync triggered")
        return true
    }
    
    func triggerBasicInApp() {
        let eventData = createEventData(template: "Basic")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_InApp", withProps: eventData)
        trackTrigger("Basic In-App")
    }
    
    func triggerCoverInApp() {
        let eventData = createEventData(template: "Cover")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_Cover_InApp", withProps: eventData)
        trackTrigger("Cover In-App")
    }
    
    func triggerInterstitialInApp() {
        let eventData = createEventData(template: "Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_Interstitial_InApp", withProps: eventData)
        trackTrigger("Interstitial In-App")
    }
    
    func triggerHalfInterstitialInApp() {
        let eventData = createEventData(template: "Half-Interstitial")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_HalfInterstitial_InApp", withProps: eventData)
        trackTrigger("Half-Interstitial In-App")
    }
    
    func triggerHeaderInApp() {
        let eventData = createEventData(template: "Header")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_Header_InApp", withProps: eventData)
        trackTrigger("Header In-App")
    }
    
    func triggerFooterInApp() {
        let eventData = createEventData(template: "Footer")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_Footer_InApp", withProps: eventData)
        trackTrigger("Footer In-App")
    }
    
    func triggerAlertInApp() {
        let eventData = createEventData(template: "Alert")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Basic_Alert_InApp", withProps: eventData)
        trackTrigger("Alert In-App")
    }
    
    private func createEventData(template: String) -> [String: Any] {
        return [
            "Template Type": "Basic",
            "Template Name": template,
            "Test Mode": true,
            "Timestamp": Date().timeIntervalSince1970,
            "User ID": CleverTap.sharedInstance()?.profileGetID() ?? "Unknown"
        ]
    }
    
    private func trackTrigger(_ templateName: String) {
        inAppNotificationCount += 1
        addNotificationLog(
            eventName: templateName,
            payload: [
                "template": templateName,
                "trigger_count": inAppNotificationCount,
                "timestamp": Date().timeIntervalSince1970
            ],
            status: .triggered
        )
    }
    
    public func addNotificationLog(eventName: String, payload: [String: Any], status: InAppNotificationLog.NotificationStatus) {
        let log = InAppNotificationLog(
            timestamp: Date(),
            eventName: eventName,
            payload: payload,
            status: status
        )
        
        receivedNotifications.insert(log, at: 0)
        
        if receivedNotifications.count > 20 {
            receivedNotifications.removeLast()
        }
        
        lastPayload = payload
    }
    
    func exportLogs() -> String {
        let logs = receivedNotifications.map { log in
            """
            Event: \(log.eventName)
            Status: \(log.status.displayText)
            Time: \(log.timestamp)
            Payload: \(log.payload)
            ---
            """
        }.joined(separator: "\n")
        
        return """
        CleverTap Comprehensive Testing Logs
        In-App Triggers: \(inAppNotificationCount)
        Push Notifications: \(pushNotificationCount)
        App Inbox Messages: \(appInboxCount)
        Connection: \(connectionStatus)
        Push Permissions: \(pushPermissionStatus)
        Export Time: \(Date())
        
        \(logs)
        """
    }
    
    func clearInAppHistory() {
        inAppNotificationCount = 0
        pushNotificationCount = 0
        appInboxCount = 0
        receivedNotifications.removeAll()
        lastPayload = [:]
        appInboxMessages.removeAll()
        
        addNotificationLog(
            eventName: "History Cleared",
            payload: ["action": "clear_history"],
            status: .triggered
        )
    }
    
    // MARK: - Manual In-App Display
    
    func resumeInAppNotifications() {
        print("🔄 Resuming in-app notifications...")
        
        DispatchQueue.main.async {
            // According to CleverTap documentation, this method resumes in-app notifications
            // and displays any queued notifications
            CleverTap.sharedInstance()?.resumeInAppNotifications()
            
            print("✅ In-app notifications resumed")
            self.addNotificationLog(
                eventName: "Resume In-App",
                payload: ["action": "resume_notifications"],
                status: .triggered
            )
        }
    }
    
    // MARK: - Connection Management
    
    func checkConnection() {
        checkCleverTapConnection()
    }

    func refreshDiagnostics() {
        checkCleverTapConnection()
        checkPushPermissions()
        refreshAppInbox()
        lastDiagnosticsRefresh = Date()
    }

    func statusSummary() -> String {
        let profileID = CleverTap.sharedInstance()?.profileGetID() ?? ""
        let profileStatus = profileID.isEmpty ? "No profile/login yet" : "Profile ID: \(String(profileID.prefix(8)))..."
        return """
        \(connectionStatus)
        \(profileStatus)
        Push: \(pushPermissionStatus)
        Inbox Count: \(appInboxCount)
        """
    }
    
    private func checkPushPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self.pushPermissionStatus = "Authorized ✅"
                case .denied:
                    self.pushPermissionStatus = "Denied ❌"
                case .notDetermined:
                    self.pushPermissionStatus = "Not Determined ⚠️"
                case .provisional:
                    self.pushPermissionStatus = "Provisional 📱"
                case .ephemeral:
                    self.pushPermissionStatus = "Ephemeral 🕐"
                @unknown default:
                    self.pushPermissionStatus = "Unknown ❓"
                }
            }
        }
    }
    
    private func initializeAppInbox() {
        CleverTap.sharedInstance()?.initializeInbox { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ App Inbox initialized successfully")
                    self.refreshAppInbox()
                } else {
                    print("❌ Failed to initialize App Inbox")
                    self.addNotificationLog(
                        eventName: "Inbox Init Failed",
                        payload: ["error": "initialization_failed"],
                        status: .failed
                    )
                }
            }
        }
    }
    
    // MARK: - Advanced In-App Notifications
    
    func triggerBannerInApp() {
        let eventData = createEventData(template: "Banner")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Banner_InApp", withProps: eventData)
        trackTrigger("Banner In-App")
    }
    
    func triggerCustomHTMLInApp() {
        let eventData = createEventData(template: "Custom HTML")
        CleverTap.sharedInstance()?.recordEvent("Trigger_CustomHTML_InApp", withProps: eventData)
        trackTrigger("Custom HTML In-App")
    }
    
    func triggerWebViewInApp() {
        let eventData = createEventData(template: "WebView")
        CleverTap.sharedInstance()?.recordEvent("Trigger_WebView_InApp", withProps: eventData)
        trackTrigger("WebView In-App")
    }
    
    func triggerScratchCardInApp() {
        let eventData = createEventData(template: "Scratch Card")
        CleverTap.sharedInstance()?.recordEvent("Trigger_ScratchCard_InApp", withProps: eventData)
        trackTrigger("Scratch Card In-App")
    }
    
    func triggerSpinTheWheelInApp() {
        let eventData = createEventData(template: "Spin The Wheel")
        CleverTap.sharedInstance()?.recordEvent("Trigger_SpinTheWheel_InApp", withProps: eventData)
        trackTrigger("Spin The Wheel In-App")
    }
    
    // MARK: - Interactive In-App Notifications
    
    func triggerRatingInApp() {
        let eventData = createEventData(template: "Rating")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Rating_InApp", withProps: eventData)
        trackTrigger("Rating In-App")
    }
    
    func triggerSurveyInApp() {
        let eventData = createEventData(template: "Survey")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Survey_InApp", withProps: eventData)
        trackTrigger("Survey In-App")
    }
    
    func triggerCarouselInApp() {
        let eventData = createEventData(template: "Carousel")
        CleverTap.sharedInstance()?.recordEvent("Trigger_Carousel_InApp", withProps: eventData)
        trackTrigger("Carousel In-App")
    }
    
    // MARK: - System In-App Functions (App Functions)
    
    /// Handles high-level "system" actions triggered from CleverTap in-app notifications
    /// via custom extras. Expected keys:
    /// - ct_system_function: "open_url", "push_permission_request", "request_app_rating"
    /// - url / deep_link: URL string for open_url
    func handleSystemInAppAction(_ extras: [String: Any]) {
        guard let functionTypeRaw = extras["ct_system_function"] as? String else { return }
        let functionType = functionTypeRaw.lowercased()
        
        switch functionType {
        case "open_url":
            handleOpenURL(extras)
            
        case "push_permission_request":
            requestPushPermission()
            addNotificationLog(
                eventName: "System In-App: Push Permission",
                payload: extras,
                status: .interacted
            )
            
        case "request_app_rating":
            requestAppRating()
            addNotificationLog(
                eventName: "System In-App: App Rating",
                payload: extras,
                status: .interacted
            )
            
        default:
            break
        }
    }
    
    private func handleOpenURL(_ extras: [String: Any]) {
        let urlString = (extras["url"] as? String) ??
                        (extras["deep_link"] as? String) ??
                        (extras["deepLink"] as? String)
        
        guard let urlStringUnwrapped = urlString,
              let url = URL(string: urlStringUnwrapped) else { return }
        
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        addNotificationLog(
            eventName: "System In-App: Open URL",
            payload: ["url": urlStringUnwrapped],
            status: .interacted
        )
    }
    
    private func requestAppRating() {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) {
                SKStoreReviewController.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview()
            }
        }
    }
    
    // MARK: - Push Notifications
    
    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.pushPermissionStatus = "Authorized ✅"
                    UIApplication.shared.registerForRemoteNotifications()
                    self.addNotificationLog(
                        eventName: "Push Permission Granted",
                        payload: ["status": "granted"],
                        status: .pushSent
                    )
                } else {
                    self.pushPermissionStatus = "Denied ❌"
                    self.addNotificationLog(
                        eventName: "Push Permission Denied",
                        payload: ["error": error?.localizedDescription ?? "Unknown"],
                        status: .failed
                    )
                }
            }
        }
    }
    
    func triggerPushNotification() {
        let eventData = [
            "Push Type": "Test Push",
            "Timestamp": Date().timeIntervalSince1970,
            "User ID": CleverTap.sharedInstance()?.profileGetID() ?? "Unknown",
            "Message": "Test push notification from CleverTap"
        ] as [String : Any]
        
        CleverTap.sharedInstance()?.recordEvent("Trigger_Push_Notification", withProps: eventData)
        pushNotificationCount += 1
        
        addNotificationLog(
            eventName: "Push Notification Triggered",
            payload: eventData,
            status: .pushSent
        )
    }
    
    func triggerRichPushNotification() {
        let eventData = [
            "Push Type": "Rich Push",
            "Timestamp": Date().timeIntervalSince1970,
            "User ID": CleverTap.sharedInstance()?.profileGetID() ?? "Unknown",
            "Message": "Rich push with image and actions",
            "Rich Media": true,
            "Actions": ["View", "Dismiss"]
        ] as [String : Any]
        
        CleverTap.sharedInstance()?.recordEvent("Trigger_Rich_Push_Notification", withProps: eventData)
        pushNotificationCount += 1
        
        addNotificationLog(
            eventName: "Rich Push Triggered",
            payload: eventData,
            status: .pushSent
        )
    }
    
    func triggerCarouselPush() {
        let eventData = [
            "Push Type": "Carousel Push",
            "Timestamp": Date().timeIntervalSince1970,
            "User ID": CleverTap.sharedInstance()?.profileGetID() ?? "Unknown",
            "Message": "Carousel push with multiple images",
            "Carousel Items": 3
        ] as [String : Any]
        
        CleverTap.sharedInstance()?.recordEvent("Trigger_Carousel_Push", withProps: eventData)
        pushNotificationCount += 1
        
        addNotificationLog(
            eventName: "Carousel Push Triggered",
            payload: eventData,
            status: .pushSent
        )
    }
    
    // MARK: - App Inbox
    
    func refreshAppInbox() {
        isRefreshingInbox = true

        if let inbox = CleverTap.sharedInstance()?.getAllInboxMessages() {
            appInboxMessages = inbox
            appInboxCount = inbox.count
            isRefreshingInbox = false

            addNotificationLog(
                eventName: "Inbox Refreshed",
                payload: ["message_count": inbox.count],
                status: .inboxUpdated
            )
            return
        }

        // Inbox can become unavailable after profile/session transitions.
        // Re-initialize once and retry fetch before failing.
        CleverTap.sharedInstance()?.initializeInbox { success in
            DispatchQueue.main.async {
                if success, let inbox = CleverTap.sharedInstance()?.getAllInboxMessages() {
                    self.appInboxMessages = inbox
                    self.appInboxCount = inbox.count

                    self.addNotificationLog(
                        eventName: "Inbox Reinitialized",
                        payload: ["message_count": inbox.count],
                        status: .inboxUpdated
                    )
                } else {
                    self.appInboxMessages = []
                    self.appInboxCount = 0

                    self.addNotificationLog(
                        eventName: "Inbox Refresh Failed",
                        payload: ["reason": "inbox_unavailable_or_nil", "reinitialize_success": success],
                        status: .failed
                    )
                }

                self.isRefreshingInbox = false
            }
        }
    }
    
    func triggerAppInboxMessage() {
        let eventData = [
            "Inbox Type": "App Inbox Message",
            "Timestamp": Date().timeIntervalSince1970,
            "User ID": CleverTap.sharedInstance()?.profileGetID() ?? "Unknown",
            "Message": "Test App Inbox message"
        ] as [String : Any]

        CleverTap.sharedInstance()?.recordEvent("Trigger_App_Inbox_Message", withProps: eventData)

        // Refresh inbox after triggering
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.refreshAppInbox()
        }

        addNotificationLog(
            eventName: "App Inbox Message Triggered",
            payload: eventData,
            status: .triggered
        )
    }

    func triggerCarouselAppInboxMessage() {
        let eventData = [
            "Inbox Type": "Carousel App Inbox Message",
            "Template": "Carousel",
            "Carousel Items": 3,
            "Timestamp": Date().timeIntervalSince1970,
            "User ID": CleverTap.sharedInstance()?.profileGetID() ?? "Unknown",
            "Message": "Test Carousel App Inbox message"
        ] as [String : Any]

        CleverTap.sharedInstance()?.recordEvent("Trigger_Carousel_App_Inbox_Message", withProps: eventData)

        // Allow campaign delivery time before inbox pull (carousel can take slightly longer).
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.refreshAppInbox()
        }

        addNotificationLog(
            eventName: "Carousel App Inbox Message Triggered",
            payload: eventData,
            status: .triggered
        )
    }
    
    func markInboxMessageAsRead(messageId: String, shouldRefresh: Bool = true) {
        CleverTap.sharedInstance()?.markReadInboxMessage(forID: messageId)
        print("📬 CleverTap: Marked inbox message as read - \(messageId)")

        if shouldRefresh {
            // Keep UI in sync immediately after single-item action.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.refreshAppInbox()
            }
        }
    }

    func markAllInboxMessagesAsRead() {
        let messageIDs = appInboxMessages.compactMap { $0.messageId }
        guard !messageIDs.isEmpty else { return }

        for messageId in messageIDs {
            markInboxMessageAsRead(messageId: messageId, shouldRefresh: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.refreshAppInbox()
        }
    }
    
    func deleteInboxMessage(messageId: String, shouldRefresh: Bool = true) {
        CleverTap.sharedInstance()?.deleteInboxMessage(forID: messageId)
        print("🗑️ CleverTap: Deleted inbox message - \(messageId)")

        if shouldRefresh {
            // Keep UI in sync immediately after single-item action.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.refreshAppInbox()
            }
        }
    }

    func deleteAllInboxMessages() {
        let messageIDs = appInboxMessages.compactMap { $0.messageId }
        guard !messageIDs.isEmpty else { return }

        for messageId in messageIDs {
            deleteInboxMessage(messageId: messageId, shouldRefresh: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.refreshAppInbox()
        }
    }
} 
