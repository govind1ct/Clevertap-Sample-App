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
        static let emailKey = "ct_email"
        static let lastImpressionDebugKey = "ct_last_impression_debug"
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
        let shouldUseRichCategory = isRichTemplatePayload(userInfo)
        let shouldUseCarouselCategory = isCarouselTemplatePayload(userInfo)

        // Record impression with normalized payload.
        // Keep identity sync guarded for actual CleverTap payloads only.
        guard let sdk = CleverTap.sharedInstance() else {
            persistImpressionDebugFlag(reason: "sdk_nil")
            super.didReceive(request, withContentHandler: contentHandler)
            return
        }

        if sdk.isCleverTapNotification(userInfo) {
            maybeSetCTUserIdentity()
        }

        let normalizedPayload = normalizedPayloadForImpression(from: userInfo)
        sdk.recordNotificationViewedEvent(withData: normalizedPayload)

        super.didReceive(request, withContentHandler: { content in
            guard let mutableContent = content.mutableCopy() as? UNMutableNotificationContent else {
                contentHandler(content)
                return
            }

            // Apply CT content extension category by payload type.
            // - CTCarouselNotification: carousel only (shows actions)
            // - CTNotification: rich/template non-carousel (no actions)
            if shouldUseCarouselCategory {
                mutableContent.categoryIdentifier = "CTCarouselNotification"
            } else if shouldUseRichCategory {
                mutableContent.categoryIdentifier = "CTNotification"
            } else if mutableContent.categoryIdentifier == "CTNotification" ||
                        mutableContent.categoryIdentifier == "CTCarouselNotification" {
                mutableContent.categoryIdentifier = ""
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
        guard let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }

        let identity = sharedDefaults.string(forKey: SharedPushIdentityConfig.identityKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = sharedDefaults.string(forKey: SharedPushIdentityConfig.emailKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        var profile: [String: Any] = [:]
        if !identity.isEmpty {
            profile["Identity"] = identity
        }
        if !email.isEmpty {
            profile["Email"] = email
        }

        guard !profile.isEmpty else {
            return
        }

        CleverTap.sharedInstance()?.onUserLogin(profile)
    }

    private func isRichTemplatePayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        // CleverTap template keys that indicate rich/template payload handling.
        let templateKeys = ["wzrk_pt_id", "pt_id", "pt_img1", "pt_title", "pt_msg"]
        return templateKeys.contains { userInfo[$0] != nil }
    }

    private func isCarouselTemplatePayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        // 1) Explicit category/template hints in payload.
        let explicitCarouselHints = [
            userInfo["category"],
            userInfo["ct_category"],
            userInfo["wzrk_category"],
            userInfo["template_type"],
            userInfo["pt_type"],
            userInfo["wzrk_pt_type"]
        ]

        for hint in explicitCarouselHints {
            if let text = normalizedString(hint), text.contains("carousel") {
                return true
            }
            if let text = normalizedString(hint), text == "ctcarouselnotification" {
                return true
            }
        }

        // 2) APNS category fallback.
        if let aps = userInfo["aps"] as? [AnyHashable: Any],
           let category = normalizedString(aps["category"]),
           category == "ctcarouselnotification" || category.contains("carousel") {
            return true
        }

        // 3) Legacy/known CleverTap carousel key patterns.
        if userInfo["pt_img2"] != nil || userInfo["pt_img3"] != nil {
            return true
        }

        // 4) Generic image key scan (pt_img1, pt_img2, ...). Carousel requires >= 2 images.
        let imageKeys = userInfo.keys
            .compactMap { $0 as? String }
            .filter { $0.lowercased().hasPrefix("pt_img") }

        return imageKeys.count >= 2
    }

    private func normalizedString(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        return raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
    }

    private func persistImpressionDebugFlag(reason: String) {
        guard let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }

        sharedDefaults.set(["reason": reason, "timestamp": Date().timeIntervalSince1970], forKey: SharedPushIdentityConfig.lastImpressionDebugKey)
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
