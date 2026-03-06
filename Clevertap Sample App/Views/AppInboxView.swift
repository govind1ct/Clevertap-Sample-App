import SwiftUI
import CleverTapSDK

struct AppInboxView: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var selectedMessage: SelectedInboxMessage?
    @State private var selectedFilter: InboxFilter = .all
    @State private var isPerformingBulkAction = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.12),
                    Color("CleverTapSecondary").opacity(0.06),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    filterBar
                    actionBar

                    if filteredMessages.isEmpty {
                        emptyStateCard
                    } else {
                        messageList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("App Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshInbox()
        }
        .sheet(item: $selectedMessage) { selection in
            MessageDetailView(message: selection.message)
        }
        .onAppear {
            inAppService.refreshAppInbox()
        }
    }

    private var filteredMessages: [CleverTapInboxMessage] {
        switch selectedFilter {
        case .all:
            return inAppService.appInboxMessages
        case .unread:
            return inAppService.appInboxMessages.filter { !$0.isRead }
        case .read:
            return inAppService.appInboxMessages.filter { $0.isRead }
        }
    }

    private var unreadCount: Int {
        inAppService.appInboxMessages.filter { !$0.isRead }.count
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CleverTap Inbox Center")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Manage Campaign Messages")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button {
                    Task {
                        await refreshInbox()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .foregroundStyle(Color("CleverTapPrimary"))
                        .rotationEffect(.degrees(inAppService.isRefreshingInbox ? 360 : 0))
                }
                .disabled(inAppService.isRefreshingInbox)
                .animation(.linear(duration: 0.9), value: inAppService.isRefreshingInbox)
            }

            HStack(spacing: 10) {
                InboxStatPill(title: "Total", value: inAppService.appInboxMessages.count, tint: Color("CleverTapPrimary"))
                InboxStatPill(title: "Unread", value: unreadCount, tint: .orange)
                InboxStatPill(title: "Read", value: inAppService.appInboxMessages.count - unreadCount, tint: .green)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            ForEach(InboxFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == filter
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color(.secondarySystemBackground)),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    inAppService.triggerAppInboxMessage()
                } label: {
                    actionLabel(title: "Trigger", icon: "plus.message.fill", tint: Color("CleverTapPrimary"))
                }

                Button {
                    markAllAsRead()
                } label: {
                    actionLabel(title: "Mark Read", icon: "checkmark.circle.fill", tint: .green)
                }
                .disabled(isPerformingBulkAction || inAppService.appInboxMessages.isEmpty)

                Button(role: .destructive) {
                    clearAllMessages()
                } label: {
                    actionLabel(title: "Clear", icon: "trash.fill", tint: .red)
                }
                .disabled(isPerformingBulkAction || inAppService.appInboxMessages.isEmpty)
            }

            Button {
                inAppService.triggerCarouselAppInboxMessage()
            } label: {
                actionLabel(title: "Trigger Carousel", icon: "square.stack.3d.forward.dottedline", tint: .orange)
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)

            Text("No messages in this view")
                .font(.headline)

            Text("Trigger a campaign message or switch the filter to view existing inbox content.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button {
                    inAppService.triggerAppInboxMessage()
                } label: {
                    Text("Send Test Message")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color("CleverTapPrimary"), in: Capsule())
                        .foregroundStyle(.white)
                }

                Button {
                    inAppService.triggerCarouselAppInboxMessage()
                } label: {
                    Text("Send Carousel")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.orange, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var messageList: some View {
        LazyVStack(spacing: 10) {
            ForEach(messageItems) { item in
                MessageRow(
                    message: item.message,
                    onTap: {
                        selectedMessage = SelectedInboxMessage(message: item.message)
                    },
                    onMarkAsRead: {
                        if let messageId = item.message.messageId {
                            inAppService.markInboxMessageAsRead(messageId: messageId)
                        }
                    },
                    onDelete: {
                        if let messageId = item.message.messageId {
                            inAppService.deleteInboxMessage(messageId: messageId)
                        }
                    }
                )
            }
        }
    }

    private var messageItems: [InboxMessageListItem] {
        filteredMessages.enumerated().map { index, message in
            let messageId = message.messageId ?? "no-id"
            let stableId = "\(messageId)-\(message.date)-\(index)"
            return InboxMessageListItem(id: stableId, message: message)
        }
    }

    private func actionLabel(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(tint)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func refreshInbox() async {
        inAppService.refreshAppInbox()
        try? await Task.sleep(nanoseconds: 200_000_000)
    }

    private func markAllAsRead() {
        guard !isPerformingBulkAction else { return }
        isPerformingBulkAction = true

        inAppService.markAllInboxMessagesAsRead()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            isPerformingBulkAction = false
        }
    }

    private func clearAllMessages() {
        guard !isPerformingBulkAction else { return }
        isPerformingBulkAction = true

        inAppService.deleteAllInboxMessages()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            isPerformingBulkAction = false
        }
    }
}

private struct SelectedInboxMessage: Identifiable {
    let id = UUID()
    let message: CleverTapInboxMessage
}

private struct InboxMessageListItem: Identifiable {
    let id: String
    let message: CleverTapInboxMessage
}

private enum InboxFilter: CaseIterable {
    case all
    case unread
    case read

    var title: String {
        switch self {
        case .all:
            return "All"
        case .unread:
            return "Unread"
        case .read:
            return "Read"
        }
    }
}

private struct InboxStatPill: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(tint)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct MessageRow: View {
    let message: CleverTapInboxMessage
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void

    @State private var showActions = false

    var body: some View {
        HStack(spacing: 12) {
            messageThumb

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(message.content?.first?.title ?? "Message")
                        .font(.subheadline)
                        .fontWeight(message.isRead ? .semibold : .bold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Spacer(minLength: 6)

                    if !message.isRead {
                        Circle()
                            .fill(Color("CleverTapPrimary"))
                            .frame(width: 8, height: 8)
                    }
                }

                if let messageText = message.content?.first?.message {
                    Text(messageText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Text(relativeDate(from: message.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        showActions.toggle()
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(message.isRead ? Color.clear : Color("CleverTapPrimary").opacity(0.35), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .confirmationDialog("Message Actions", isPresented: $showActions) {
            if !message.isRead {
                Button("Mark as Read") { onMarkAsRead() }
            }
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var messageThumb: some View {
        Group {
            if let mediaUrl = message.content?.first?.mediaUrl {
                AppAsyncImage(urlString: mediaUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        placeholderThumb
                    }
                }
            } else {
                placeholderThumb
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var placeholderThumb: some View {
        ZStack {
            LinearGradient(
                colors: [Color("CleverTapPrimary").opacity(0.85), Color("CleverTapSecondary").opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "envelope.fill")
                .foregroundStyle(.white)
                .font(.headline)
        }
    }

    private func relativeDate(from rawSeconds: UInt) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(rawSeconds))
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MessageDetailView: View {
    let message: CleverTapInboxMessage
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private var contents: [CleverTapInboxMessageContent] {
        message.content ?? []
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(message.campaignId ?? "Message")
                            .font(.title2)
                            .fontWeight(.bold)

                        if contents.count > 1 {
                            TabView(selection: $currentPage) {
                                ForEach(Array(contents.indices), id: \.self) { index in
                                    messageContentCard(contents[index])
                                        .tag(index)
                                }
                            }
                            .frame(height: 330)
                            .tabViewStyle(.page(indexDisplayMode: .automatic))

                            Text("Slide \(currentPage + 1) of \(contents.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let content = contents.first {
                            messageContentCard(content)
                        } else {
                            Text("No content available for this inbox message.")
                                .font(.body)
                                .foregroundStyle(.secondary)
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

    @ViewBuilder
    private func messageContentCard(_ content: CleverTapInboxMessageContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let mediaUrl = content.mediaUrl {
                AppAsyncImage(urlString: mediaUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    }
                }
                .frame(maxHeight: 250)
                .cornerRadius(12)
            }

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
}

#Preview {
    NavigationView {
        AppInboxView()
    }
}
