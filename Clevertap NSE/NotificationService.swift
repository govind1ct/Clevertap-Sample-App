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
        static let traceLogsKey = "ct_nse_trace_logs"
        static let maxTraceLogEntries = 40
    }

    // MARK: - Main Entry - this is where we have to define the Rich Media Support
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping     (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        self.bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            appendTrace(
                event: "no_mutable_content",
                userInfo: request.content.userInfo,
                requestID: request.identifier
            )
            contentHandler(request.content)
            return
        }

        let userInfo = bestAttemptContent.userInfo
        appendTrace(event: "did_receive_start", userInfo: userInfo, requestID: request.identifier)
        shouldUseRichCategory = isRichTemplatePayload(userInfo)
        shouldUseManualCarouselCategory = isManualCarouselTemplatePayload(userInfo)

        // Keep identity sync guarded for actual CleverTap payloads only.
        guard let sdk = CleverTap.sharedInstance() else {
            // Avoid noisy debug flips from non-CleverTap notifications.
            if isLikelyCleverTapPayload(userInfo) {
                persistImpressionDebugFlag(reason: "sdk_nil")
            }
            appendTrace(event: "sdk_nil", userInfo: userInfo, requestID: request.identifier)
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

        guard sdk.isCleverTapNotification(userInfo) else {
            if isLikelyCleverTapPayload(userInfo) {
                persistImpressionDebugFlag(reason: "not_ct_payload")
            }
            appendTrace(event: "not_ct_payload", userInfo: userInfo, requestID: request.identifier)
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

        maybeSetCTUserIdentity()
        appendTrace(event: "ct_payload_verified", userInfo: userInfo, requestID: request.identifier)
        // Per CleverTap docs, pass original payload while recording viewed event.
        sdk.recordNotificationViewedEvent(withData: userInfo)
        persistImpressionDebugFlag(reason: "viewed_recorded")
        appendTrace(event: "viewed_recorded", userInfo: userInfo, requestID: request.identifier)

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
            appendTrace(event: "time_will_expire", userInfo: bestAttemptContent.userInfo)
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

    private func isLikelyCleverTapPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        for key in userInfo.keys {
            if let keyString = key as? String, keyString.lowercased().hasPrefix("wzrk_") {
                return true
            }
        }
        return false
    }

    private func persistImpressionDebugFlag(reason: String) {
        guard let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }

        sharedDefaults.set(["reason": reason, "timestamp": Date().timeIntervalSince1970], forKey: SharedPushIdentityConfig.lastImpressionDebugKey)
    }

    private func appendTrace(
        event: String,
        userInfo: [AnyHashable: Any],
        requestID: String? = nil
    ) {
        guard let sharedDefaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }

        var logs = sharedDefaults.array(forKey: SharedPushIdentityConfig.traceLogsKey) as? [[String: String]] ?? []

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let wzrkID = stringValue(in: userInfo, keys: ["wzrk_id", "W$id", "wzrk_pid"]) ?? ""
        let ptID = stringValue(in: userInfo, keys: ["pt_id", "wzrk_pt_id"]) ?? ""
        let profileID = CleverTap.sharedInstance()?.profileGetID() ?? ""

        var entry: [String: String] = [
            "timestamp": timestamp,
            "event": event,
            "is_ct_candidate": isLikelyCleverTapPayload(userInfo) ? "true" : "false",
            "wzrk_id": wzrkID,
            "pt_id": ptID,
            "ct_profile_id": profileID,
            "category": shouldUseManualCarouselCategory ? "CTCarouselNotification" : (shouldUseRichCategory ? "CTNotification" : "none")
        ]

        if let requestID, !requestID.isEmpty {
            entry["request_id"] = requestID
        }

        logs.append(entry)
        if logs.count > SharedPushIdentityConfig.maxTraceLogEntries {
            logs.removeFirst(logs.count - SharedPushIdentityConfig.maxTraceLogEntries)
        }

        sharedDefaults.set(logs, forKey: SharedPushIdentityConfig.traceLogsKey)
    }

    private func stringValue(in userInfo: [AnyHashable: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = userInfo[key] {
                let stringValue = String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
                if !stringValue.isEmpty {
                    return stringValue
                }
            }
        }
        return nil
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
