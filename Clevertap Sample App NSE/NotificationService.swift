//
//  NotificationService.swift
//  Clevertap Sample App NSE
//
//  Created by Govind Pathak on 05/01/26.
//


import UserNotifications
import CleverTapSDK
import CTNotificationService

class NotificationService: CTNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    // MARK: - Main Entry - this is where we have to define the Rich Media Support
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping     (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        let userInfo = bestAttemptContent.userInfo

        // ✅ Check if this is a CleverTap push
        if CleverTap.sharedInstance()?.isCleverTapNotification(userInfo) == true {

            // ✅ Ensure same user identity is used inside NSE
            maybeSetCTUserIdentity()

            // ✅ Record push impression (VERY IMPORTANT)
            CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: userInfo)

            // ✅ Let CleverTap handle Rich Push rendering
            super.didReceive(request, withContentHandler: contentHandler)

        } else {
            // ❌ Non-CleverTap notification — deliver as-is
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Time Expiry Fallback
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - User Identity Sync (App ↔ NSE)
    private func maybeSetCTUserIdentity() {
        guard
            let sharedDefaults = UserDefaults(suiteName: "group.com.yourcompany.clevertap"),
            let identity = sharedDefaults.string(forKey: "ct_user_identity")
        else {
            return
        }

        CleverTap.sharedInstance()?.onUserLogin([
            "Identity": identity
        ])
    }
}

