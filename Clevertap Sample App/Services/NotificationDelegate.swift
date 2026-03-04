import Foundation
import UserNotifications
import UIKit
import CleverTapSDK

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, UIApplicationDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // MARK: - UIApplicationDelegate Methods

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")

        UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        UserDefaults.standard.set(tokenString, forKey: "deviceTokenString")

        CleverTap.sharedInstance()?.setPushToken(deviceToken)

        CleverTapService.shared.setUserProperty(key: "Device Token", value: tokenString)
        CleverTapService.shared.setUserProperty(key: "Push Enabled", value: true)
        CleverTapService.shared.setUserProperty(key: "Last Token Update", value: Date())

        let eventData: [String: Any] = [
            "Device Token": tokenString,
            "Platform": "iOS",
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]

        CleverTap.sharedInstance()?.recordEvent("Device Token Registered", withProps: eventData)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")

        let eventData: [String: Any] = [
            "Error": error.localizedDescription,
            "Platform": "iOS"
        ]

        CleverTap.sharedInstance()?.recordEvent("Device Token Registration Failed", withProps: eventData)

        CleverTapService.shared.setUserProperty(key: "Push Enabled", value: false)
        CleverTapService.shared.setUserProperty(key: "Push Error", value: error.localizedDescription)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        recordPushImpressionIfPossible(userInfo: userInfo)
        CleverTap.sharedInstance()?.handleNotification(withData: userInfo)
        completionHandler(.newData)
    }

    // MARK: - UNUserNotificationCenterDelegate Methods

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        recordPushImpressionIfPossible(userInfo: notification.request.content.userInfo)

        trackNotificationEvent(notification: notification, action: "Received")

        // Foreground push should still be visible.
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let notification = response.notification

        trackNotificationEvent(notification: notification, action: "Clicked")

        CleverTap.sharedInstance()?.handleNotification(withData: notification.request.content.userInfo)
        handleNotificationAction(response: response)

        completionHandler()
    }

    // MARK: - Helper Methods

    private func trackNotificationEvent(notification: UNNotification, action: String) {
        let userInfo = notification.request.content.userInfo

        var eventData: [String: Any] = [
            "Action": action,
            "Notification ID": notification.request.identifier,
            "Title": notification.request.content.title,
            "Body": notification.request.content.body
        ]

        if let campaignId = userInfo["wzrk_id"] as? String {
            eventData["Campaign ID"] = campaignId
        }

        if let campaignName = userInfo["wzrk_nm"] as? String {
            eventData["Campaign Name"] = campaignName
        }

        CleverTap.sharedInstance()?.recordEvent("Push Notification \(action)", withProps: eventData)
    }

    private func handleNotificationAction(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        if let deepLink = userInfo["deep_link"] as? String {
            print("Deep link: \(deepLink)")
        }

        if let customAction = userInfo["custom_action"] as? String {
            print("Custom action: \(customAction)")
        }
    }

    private func recordPushImpressionIfPossible(userInfo: [AnyHashable: Any]) {
        let normalizedPayload = normalizedPayloadForImpression(from: userInfo)
        CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: normalizedPayload)
    }

    private func normalizedPayloadForImpression(from userInfo: [AnyHashable: Any]) -> [AnyHashable: Any] {
        var payload = userInfo

        if payload["wzrk_id"] == nil {
            if let fallbackID = payload["W$id"] ?? payload["wzrk_pt_id"] ?? payload["pt_id"] {
                payload["wzrk_id"] = fallbackID
            }
        }

        if payload["wzrk_nm"] == nil, let title = payload["pt_title"] {
            payload["wzrk_nm"] = title
        }

        return payload
    }
}

extension NotificationDelegate {
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status = settings.authorizationStatus

                var permissionStatus = ""
                switch status {
                case .authorized: permissionStatus = "Authorized"
                case .denied: permissionStatus = "Denied"
                case .notDetermined: permissionStatus = "Not Determined"
                case .provisional: permissionStatus = "Provisional"
                case .ephemeral: permissionStatus = "Ephemeral"
                @unknown default: permissionStatus = "Unknown"
                }

                CleverTapService.shared.setUserProperty(key: "Notification Permission", value: permissionStatus)
                print("Notification permission status: \(permissionStatus)")
            }
        }
    }

    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    CleverTapService.shared.setUserProperty(key: "Notification Permission", value: "Authorized")
                } else {
                    CleverTapService.shared.setUserProperty(key: "Notification Permission", value: "Denied")
                }

                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
}
