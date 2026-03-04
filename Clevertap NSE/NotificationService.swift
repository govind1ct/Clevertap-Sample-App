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
    private enum SharedPushIdentityConfig {
        static let appGroupID = "group.com.govind.clevertap-sample-app"
        static let identityKey = "ct_identity"
    }

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

        // Track view for CT payloads, but always let CTNotificationService do rich rendering.
        if CleverTap.sharedInstance()?.isCleverTapNotification(userInfo) == true {
            maybeSetCTUserIdentity()
            CleverTap.sharedInstance()?.recordNotificationViewedEvent(withData: userInfo)
        }

        super.didReceive(request, withContentHandler: { content in
            guard let mutableContent = content.mutableCopy() as? UNMutableNotificationContent else {
                contentHandler(content)
                return
            }

            // Carousel/content-extension rendering requires category mapping.
            // Some template payloads may omit aps.category.
            if mutableContent.categoryIdentifier.isEmpty {
                mutableContent.categoryIdentifier = "CTNotification"
            }
            contentHandler(mutableContent)
        })
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
            let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID),
            let identity = sharedDefaults.string(forKey: SharedPushIdentityConfig.identityKey)
        else {
            return
        }

        CleverTap.sharedInstance()?.onUserLogin([
            "Identity": identity
        ])
    }
}
