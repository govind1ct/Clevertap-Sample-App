import CTNotificationContent
import CleverTapSDK

class NotificationViewController: CTNotificationViewController {
    override func userDidReceive(_ response: UNNotificationResponse?) {
        let payload = response?.notification.request.content.userInfo
        if response?.actionIdentifier == "action_2" {
            CleverTap.sharedInstance()?.recordNotificationClickedEvent(withData: payload ?? [:])
        }
    }
}
