import SwiftUI
import CleverTapSDK

struct AppInboxView: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var selectedMessage: CleverTapInboxMessage?
    @State private var showMessageDetail = false
    @State private var refreshing = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        Color("CleverTapPrimary").opacity(0.1),
                        Color("CleverTapSecondary").opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Content
                    if inAppService.appInboxMessages.isEmpty {
                        emptyStateView
                    } else {
                        messageListView
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshInbox()
            }
            .sheet(isPresented: $showMessageDetail) {
                if let message = selectedMessage {
                    MessageDetailView(message: message)
                }
            }
        }
        .onAppear {
            inAppService.refreshAppInbox()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "tray.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("App Inbox")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("\(inAppService.appInboxMessages.count) messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        refreshing = true
                    }
                    inAppService.refreshAppInbox()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            refreshing = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(refreshing ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatCount(refreshing ? 10 : 0, autoreverses: false), value: refreshing)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                InboxActionButton(
                    title: "Trigger Message",
                    icon: "plus.message",
                    color: .blue,
                    action: {
                        inAppService.triggerAppInboxMessage()
                    }
                )
                
                InboxActionButton(
                    title: "Mark All Read",
                    icon: "checkmark.circle",
                    color: .green,
                    action: markAllAsRead
                )
                
                InboxActionButton(
                    title: "Clear All",
                    icon: "trash",
                    color: .red,
                    action: clearAllMessages
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Empty state illustration
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("CleverTapPrimary").opacity(0.2),
                                Color("CleverTapSecondary").opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "tray")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Messages Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Your inbox messages will appear here.\nTrigger a test message to get started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            Button(action: {
                inAppService.triggerAppInboxMessage()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.message")
                    Text("Trigger Test Message")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 25)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Message List View
    private var messageListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(inAppService.appInboxMessages, id: \.messageId) { message in
                    MessageRow(
                        message: message,
                        onTap: {
                            selectedMessage = message
                            showMessageDetail = true
                        },
                        onMarkAsRead: {
                            if let messageId = message.messageId {
                                inAppService.markInboxMessageAsRead(messageId: messageId)
                            }
                        },
                        onDelete: {
                            if let messageId = message.messageId {
                                inAppService.deleteInboxMessage(messageId: messageId)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Actions
    private func refreshInbox() async {
        inAppService.refreshAppInbox()
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay for better UX
    }
    
    private func markAllAsRead() {
        for message in inAppService.appInboxMessages {
            if let messageId = message.messageId {
                inAppService.markInboxMessageAsRead(messageId: messageId)
            }
        }
        inAppService.refreshAppInbox()
    }
    
    private func clearAllMessages() {
        for message in inAppService.appInboxMessages {
            if let messageId = message.messageId {
                inAppService.deleteInboxMessage(messageId: messageId)
            }
        }
        inAppService.refreshAppInbox()
    }
}

// MARK: - Supporting Views

struct InboxActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct MessageRow: View {
    let message: CleverTapInboxMessage
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void
    
    @State private var showActions = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Message image
                if let content = message.content?.first,
                   let mediaUrl = content.mediaUrl {
                    AppAsyncImage(urlString: mediaUrl) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        )
                }
                
                // Message content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(message.content?.first?.title ?? "Message")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if !message.isRead {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    if let messageText = message.content?.first?.message {
                        Text(messageText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text(formatDate(Date(timeIntervalSince1970: TimeInterval(message.date))))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: { showActions.toggle() }) {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .confirmationDialog("Message Actions", isPresented: $showActions) {
            if !message.isRead {
                Button("Mark as Read") { onMarkAsRead() }
            }
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MessageDetailView: View {
    let message: CleverTapInboxMessage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Message header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(message.campaignId ?? "Message")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Message image if available
                        if let content = message.content?.first,
                           let mediaUrl = content.mediaUrl {
                            AppAsyncImage(urlString: mediaUrl) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 200)
                                        .overlay(
                                            ProgressView()
                                        )
                                }
                            }
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                        }
                        
                        // Message content
                        if let content = message.content?.first {
                            if let title = content.title {
                                Text(title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            if let messageText = content.message {
                                Text(messageText)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Message Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    AppInboxView()
} 
