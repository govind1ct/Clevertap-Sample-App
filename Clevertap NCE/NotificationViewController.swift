import CTNotificationContent
import CleverTapSDK

class NotificationViewController: CTNotificationViewController {
    override func userDidReceive(_ response: UNNotificationResponse?) {
        // Preserve CleverTap's default handling for rich push templates and carousel actions.
        super.userDidReceive(response)
    }
}
