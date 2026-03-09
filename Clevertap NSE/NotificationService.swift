//
//  NotificationService.swift
//  Clevertap Sample App NSE
//
//  Created by Govind Pathak on 05/01/26.



import UserNotifications
import CleverTapSDK
import CTNotificationService

class NotificationService: CTNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?
    private var shouldUseRichCategory = false
    private var shouldUseManualCarouselCategory = false
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
        shouldUseRichCategory = isRichTemplatePayload(userInfo)
        shouldUseManualCarouselCategory = isManualCarouselTemplatePayload(userInfo)

        // Record impression with normalized payload.
        // Keep identity sync guarded for actual CleverTap payloads only.
        guard let sdk = CleverTap.sharedInstance() else {
            persistImpressionDebugFlag(reason: "sdk_nil")
            super.didReceive(request, withContentHandler: { content in
                guard let mutableContent = content.mutableCopy() as? UNMutableNotificationContent else {
                    contentHandler(content)
                    return
                }
                self.applyRichCategoryIfNeeded(on: mutableContent)
                contentHandler(mutableContent)
            })
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

            self.applyRichCategoryIfNeeded(on: mutableContent)
            contentHandler(mutableContent)
        })
    }

    // MARK: - Time Expiry Fallback
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler,
           let bestAttemptContent = bestAttemptContent {
            applyRichCategoryIfNeeded(on: bestAttemptContent)
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

    private func isManualCarouselTemplatePayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        // CleverTap template keys:
        // - Auto carousel: pt_id = pt_carousel
        // - Manual carousel: pt_id = pt_manual_carousel
        let templateIDCandidates = [
            userInfo["pt_id"],
            userInfo["wzrk_pt_id"],
            userInfo["pt_type"],
            userInfo["wzrk_pt_type"],
            userInfo["template_type"]
        ]

        for candidate in templateIDCandidates {
            if let value = normalizedString(candidate), value == "ptmanualcarousel" {
                return true
            }
        }

        // Explicit manual hints if integrator sends category variants.
        let manualHints = [
            userInfo["category"],
            userInfo["ct_category"],
            userInfo["wzrk_category"]
        ]

        for hint in manualHints {
            if let value = normalizedString(hint), value.contains("manualcarousel") {
                return true
            }
        }

        return false
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

    private func applyRichCategoryIfNeeded(on content: UNMutableNotificationContent) {
        // - Manual carousel -> CTCarouselNotification (Back/Next actions)
        // - Auto carousel + other rich templates -> CTNotification (no manual nav actions)
        if shouldUseManualCarouselCategory {
            content.categoryIdentifier = "CTCarouselNotification"
        } else if shouldUseRichCategory {
            content.categoryIdentifier = "CTNotification"
        } else if content.categoryIdentifier == "CTNotification" ||
                    content.categoryIdentifier == "CTCarouselNotification" {
            content.categoryIdentifier = ""
        }
    }
}
