import SwiftUI

struct AppInboxView: View {
    @State private var notifications: [Notification] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(notifications) { notification in
                    NotificationRow(notification: notification)
                }
            }
            .navigationTitle("App Inbox")
            .refreshable {
                await loadNotifications()
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .task {
            await loadNotifications()
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        // TODO: Implement Clevertap notification fetching
        isLoading = false
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notification.title)
                .font(.headline)
            
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(notification.date.formatted())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct Notification: Identifiable {
    let id: String
    let title: String
    let message: String
    let date: Date
    let type: NotificationType
    var isRead: Bool
    
    enum NotificationType {
        case push
        case inApp
        case inbox
    }
}

#Preview {
    AppInboxView()
} 