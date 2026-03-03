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
        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(tokenString)")
        
        // Store device token in UserDefaults for display in settings
        UserDefaults.standard.set(deviceToken, forKey: "deviceToken")
        UserDefaults.standard.set(tokenString, forKey: "deviceTokenString")
        
        // Register device token with CleverTap
        CleverTap.sharedInstance()?.setPushToken(deviceToken)
        
        // Store device token in CleverTap user profile
        CleverTapService.shared.setUserProperty(key: "Device Token", value: tokenString)
        CleverTapService.shared.setUserProperty(key: "Push Enabled", value: true)
        CleverTapService.shared.setUserProperty(key: "Last Token Update", value: Date())
        
        // Track device token registration event
        let eventData: [String: Any] = [
            "Device Token": tokenString,
            "Platform": "iOS",
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Device Token Registered", withProps: eventData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        
        // Track failed registration
        let eventData: [String: Any] = [
            "Error": error.localizedDescription,
            "Platform": "iOS"
        ]
        
        CleverTap.sharedInstance()?.recordEvent("Device Token Registration Failed", withProps: eventData)
        
        // Update user profile
        CleverTapService.shared.setUserProperty(key: "Push Enabled", value: false)
        CleverTapService.shared.setUserProperty(key: "Push Error", value: error.localizedDescription)
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Track notification received
        trackNotificationEvent(notification: notification, action: "Received")
        
        // Show notification even when app is in foreground
        completionHandler([.badge, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let notification = response.notification
        
        // Track notification interaction
        trackNotificationEvent(notification: notification, action: "Clicked")
        
        // Handle CleverTap notification
        CleverTap.sharedInstance()?.handleNotification(withData: notification.request.content.userInfo)
        
        // Handle custom notification actions here
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
        
        // Add CleverTap specific data if available
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
        
        // Handle deep linking or custom actions based on notification payload
        if let deepLink = userInfo["deep_link"] as? String {
            // Handle deep link navigation
            print("Deep link: \(deepLink)")
            
            // You can add navigation logic here
            // For example, navigate to specific product or screen
        }
        
        // Handle other custom actions
        if let customAction = userInfo["custom_action"] as? String {
            print("Custom action: \(customAction)")
            
            // Handle custom actions like opening specific screens
            switch customAction {
            case "view_cart":
                // Navigate to cart
                break
            case "view_offers":
                // Navigate to offers
                break
            default:
                break
            }
        }
    }
}

// MARK: - Extension for easy access to notification methods

extension NotificationDelegate {
    
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                let status = settings.authorizationStatus
                
                var permissionStatus = ""
                switch status {
                case .authorized:
                    permissionStatus = "Authorized"
                case .denied:
                    permissionStatus = "Denied"
                case .notDetermined:
                    permissionStatus = "Not Determined"
                case .provisional:
                    permissionStatus = "Provisional"
                case .ephemeral:
                    permissionStatus = "Ephemeral"
                @unknown default:
                    permissionStatus = "Unknown"
                }
                
                // Update user profile with permission status
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
