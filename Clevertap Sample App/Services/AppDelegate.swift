//import UIKit
//import CleverTapSDK
//import UserNotifications
//import FirebaseCore
//#if canImport(PayUCheckoutProKit)
//import PayUCheckoutProKit
//#endif
//
//class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CleverTapInAppNotificationDelegate, CleverTapPushNotificationDelegate {
//    
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        
//        // Configure Firebase first
//        FirebaseApp.configure()
//        
//        // Configure CleverTap
//        CleverTap.autoIntegrate()
//        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)
//
//        #if canImport(PayUCheckoutProKit)
//        PayUCheckoutPro.start()
//        #endif
//        
//        // IMPORTANT: Set CleverTap as the in-app notification delegate
//        CleverTap.sharedInstance()?.setInAppNotificationDelegate(self)
//        
//        // Print CleverTap Profile ID for debugging
//        if let profileId = CleverTap.sharedInstance()?.profileGetID() {
//            print("🔧 CleverTap Profile ID: \(profileId)")
//        }
//        
//        // Configure push notifications
//        UNUserNotificationCenter.current().delegate = self
//        CleverTap.sharedInstance()?.setPushNotificationDelegate(self)
//        configureRichPushCategories()
//
//        // Register for push notifications
//        registerForPushNotifications()
//        
//        print("✅ AppDelegate: CleverTap configured with in-app notification delegate")
//        
//        // Handle launch from notification
//        if let notificationPayload = launchOptions?[.remoteNotification] as? [String: Any] {
//            // App was launched from a push notification
//            CleverTap.sharedInstance()?.handleNotification(withData: notificationPayload)
//            print("🚀 App launched from notification: \(notificationPayload)")
//        }
//        
//        return true
//    }
//    
//    // MARK: - Push Notification Methods
//    
//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // Forward to NotificationDelegate
//        NotificationDelegate.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
//    }
//    
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        // Forward to NotificationDelegate
//        NotificationDelegate.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
//    }
//    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        
//        // Handle CleverTap notification
//        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
//        
//        // Track notification received
//        let eventData: [String: Any] = [
//            "Notification Data": userInfo,
//            "App State": application.applicationState == .background ? "Background" : "Foreground"
//        ]
//        CleverTap.sharedInstance()?.recordEvent("Push Notification Received", withProps: eventData)
//        
//        completionHandler(.newData)
//    }
//    
//    // MARK: - UNUserNotificationCenterDelegate Methods
//
//    func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        willPresent notification: UNNotification,
//        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//    ) {
//        NotificationDelegate.shared.userNotificationCenter(
//            center,
//            willPresent: notification,
//            withCompletionHandler: completionHandler
//        )
//    }
//
//    func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        didReceive response: UNNotificationResponse,
//        withCompletionHandler completionHandler: @escaping () -> Void
//    ) {
//        NotificationDelegate.shared.userNotificationCenter(
//            center,
//            didReceive: response,
//            withCompletionHandler: completionHandler
//        )
//    }
//
//    // MARK: - Helper Methods
//    
//    private func configureRichPushCategories() {
//        let backAction = UNNotificationAction(
//            identifier: "action_1",
//            title: "Back",
//            options: []
//        )
//
//        let nextAction = UNNotificationAction(
//            identifier: "action_2",
//            title: "Next",
//            options: []
//        )
//
//        let viewInAppAction = UNNotificationAction(
//            identifier: "action_3",
//            title: "View In App",
//            options: [.foreground]
//        )
//
//        let category = UNNotificationCategory(
//            identifier: "CTNotification",
//            actions: [backAction, nextAction, viewInAppAction],
//            intentIdentifiers: [],
//            options: []
//        )
//
//        UNUserNotificationCenter.current().setNotificationCategories([category])
//    }
//
//    private func registerForPushNotifications() {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//            if granted {
//                print("✅ Push notifications permission granted")
//                DispatchQueue.main.async {
//                    UIApplication.shared.registerForRemoteNotifications()
//                }
//            } else {
//                print("❌ Push notifications permission denied: \(error?.localizedDescription ?? "Unknown error")")
//            }
//        }
//    }
//}
//
//// MARK: - CleverTap In-App Notification Delegate
//
//extension AppDelegate {
//    
//    // Called when an in-app notification is about to be displayed
//    func inAppNotificationDidShow(_ inAppNotification: [AnyHashable : Any]!, with formData: [AnyHashable : Any]!) {
//        print("🎯 CleverTap In-App Notification Did Show!")
//        print("📋 Notification Data: \(inAppNotification ?? [:])")
//        print("📋 Form Data: \(formData ?? [:])")
//        
//        // Convert AnyHashable keys to String keys
//        let convertedPayload = (inAppNotification ?? [:]).reduce(into: [String: Any]()) { result, element in
//            if let key = element.key as? String {
//                result[key] = element.value
//            }
//        }
//        
//        // Update our service
//        DispatchQueue.main.async {
//            CleverTapInAppService.shared.lastPayload = [
//                "type": "notification_shown",
//                "notification": inAppNotification ?? [:],
//                "form_data": formData ?? [:],
//                "timestamp": Date().timeIntervalSince1970
//            ]
//            
//            CleverTapInAppService.shared.inAppNotificationCount += 1
//            
//            CleverTapInAppService.shared.addNotificationLog(
//                eventName: "In-App Shown",
//                payload: convertedPayload,
//                status: .displayed
//            )
//        }
//    }
//    
//    // Called when user taps on an in-app notification button
//    func inAppNotificationButtonTapped(withCustomExtras customExtras: [AnyHashable : Any]!) {
//        print("🎯 CleverTap In-App Button Tapped!")
//        print("📋 Custom Extras: \(customExtras ?? [:])")
//        
//        // Convert AnyHashable keys to String keys
//        let convertedPayload = (customExtras ?? [:]).reduce(into: [String: Any]()) { result, element in
//            if let key = element.key as? String {
//                result[key] = element.value
//            }
//        }
//        
//        // Update our service
//        DispatchQueue.main.async {
//            CleverTapInAppService.shared.lastPayload = [
//                "type": "button_tapped",
//                "custom_extras": customExtras ?? [:],
//                "timestamp": Date().timeIntervalSince1970
//            ]
//
//            // Route any supported "system in-app" actions (Open URL, Push Permission, App Rating)
//            CleverTapInAppService.shared.handleSystemInAppAction(convertedPayload)
//            
//            CleverTapInAppService.shared.addNotificationLog(
//                eventName: "In-App Button Tapped",
//                payload: convertedPayload,
//                status: .interacted
//            )
//        }
//    }
//    
//    // Called when an in-app notification is dismissed
//    func inAppNotificationDidDismiss(_ inAppNotification: [AnyHashable : Any]!, with formData: [AnyHashable : Any]!) {
//        print("🎯 CleverTap In-App Notification Did Dismiss!")
//        print("📋 Notification Data: \(inAppNotification ?? [:])")
//        print("📋 Form Data: \(formData ?? [:])")
//        
//        // Update our service
//        DispatchQueue.main.async {
//            CleverTapInAppService.shared.lastPayload = [
//                "type": "notification_dismissed",
//                "notification": inAppNotification ?? [:],
//                "form_data": formData ?? [:],
//                "timestamp": Date().timeIntervalSince1970
//            ]
//        }
//    }
//    
//    // Helper method to check CleverTap initialization
//    func checkCleverTapStatus() {
//        if let cleverTapID = CleverTap.sharedInstance()?.profileGetID() {
//            print("✅ CleverTap initialized successfully with ID: \(cleverTapID)")
//        } else {
//            print("❌ CleverTap not initialized properly")
//        }
//        
//        // Log CleverTap version from unified diagnostics helper
//        let sdkVersion = CleverTapService.shared.sdkVersionString()
//        print("🔧 CleverTap SDK Version: \(sdkVersion)")
//        
//        // Check if in-app delegate is set
//        print("🔧 In-App Delegate Status: Configured in init()")
//    }
//} 
import UIKit
import CleverTapSDK
import UserNotifications
import FirebaseCore
#if canImport(PayUCheckoutProKit)
import PayUCheckoutProKit
#endif

class AppDelegate: UIResponder,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   CleverTapInAppNotificationDelegate,
                   CleverTapPushNotificationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // MARK: - Firebase
        FirebaseApp.configure()

        // MARK: - CleverTap Setup
        CleverTap.autoIntegrate()
        CleverTap.setDebugLevel(CleverTapLogLevel.debug.rawValue)

        #if canImport(PayUCheckoutProKit)
        PayUCheckoutPro.start()
        #endif

        // In-App delegate
        CleverTap.sharedInstance()?.setInAppNotificationDelegate(self)

        // Push delegate
        CleverTap.sharedInstance()?.setPushNotificationDelegate(self)

        // Route UNUserNotificationCenter callbacks through one path to avoid duplicate tracking.
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

        // Register CleverTap rich push category/actions.
        configureRichPushCategories()

        // Register for push
        registerForPush()

        // Debug Profile ID
        if let profileId = CleverTap.sharedInstance()?.profileGetID() {
            print("🔧 CleverTap Profile ID: \(profileId)")
        }
        CleverTapService.shared.syncPushIdentityForExtensions()

        // Handle app launch from push
        if let notificationPayload = launchOptions?[.remoteNotification] as? [String: Any] {
            CleverTap.sharedInstance()?.handleNotification(withData: notificationPayload)
        }

        print("✅ CleverTap fully configured")
        return true
    }

    // MARK: - Push Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationDelegate.shared.application(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationDelegate.shared.application(
            application,
            didFailToRegisterForRemoteNotificationsWithError: error
        )
    }

    // MARK: - Background Push

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotificationDelegate.shared.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }

    // MARK: - Foreground Push

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        NotificationDelegate.shared.userNotificationCenter(
            center,
            willPresent: notification,
            withCompletionHandler: completionHandler
        )
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationDelegate.shared.userNotificationCenter(
            center,
            didReceive: response,
            withCompletionHandler: completionHandler
        )
    }

    // MARK: - Push Permission

    private func configureRichPushCategories() {
        let backAction = UNNotificationAction(identifier: "action_1", title: "Back", options: [])
        let nextAction = UNNotificationAction(identifier: "action_2", title: "Next", options: [])
        let viewInAppAction = UNNotificationAction(identifier: "action_3", title: "View In App", options: [])

        let category = UNNotificationCategory(
            identifier: "CTNotification",
            actions: [backAction, nextAction, viewInAppAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func  registerForPush() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Push permission denied: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }

}

// MARK: - CleverTap In-App Delegate

extension AppDelegate {

    func inAppNotificationDidShow(
        _ inAppNotification: [AnyHashable : Any]!,
        with formData: [AnyHashable : Any]!
    ) {
        print("🎯 In-App Shown: \(inAppNotification ?? [:])")

        DispatchQueue.main.async {
            CleverTapInAppService.shared.lastPayload = [
                "type": "notification_shown",
                "notification": inAppNotification ?? [:],
                "form_data": formData ?? [:],
                "timestamp": Date().timeIntervalSince1970
            ]
            CleverTapInAppService.shared.inAppNotificationCount += 1
        }
    }

    func inAppNotificationButtonTapped(
        withCustomExtras customExtras: [AnyHashable : Any]!
    ) {
        print("🎯 In-App Button Tapped: \(customExtras ?? [:])")

        let convertedPayload = (customExtras ?? [:]).reduce(into: [String: Any]()) {
            if let key = $1.key as? String {
                $0[key] = $1.value
            }
        }

        DispatchQueue.main.async {
            CleverTapInAppService.shared.lastPayload = [
                "type": "button_tapped",
                "custom_extras": customExtras ?? [:],
                "timestamp": Date().timeIntervalSince1970
            ]

            CleverTapInAppService.shared.handleSystemInAppAction(convertedPayload)
        }
    }

    func inAppNotificationDidDismiss(
        _ inAppNotification: [AnyHashable : Any]!,
        with formData: [AnyHashable : Any]!
    ) {
        print("🎯 In-App Dismissed")

        DispatchQueue.main.async {
            CleverTapInAppService.shared.lastPayload = [
                "type": "notification_dismissed",
                "notification": inAppNotification ?? [:],
                "form_data": formData ?? [:],
                "timestamp": Date().timeIntervalSince1970
            ]
        }
    }
}
