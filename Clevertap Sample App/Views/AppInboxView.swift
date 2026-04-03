import SwiftUI
import CleverTapSDK

struct AppInboxView: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var selectedMessage: SelectedInboxMessage?
    @State private var selectedFilter: InboxFilter = .all
    @State private var isPerformingBulkAction = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    mastheadSection
                    summaryRail
                    commandDeck

                    if filteredMessages.isEmpty {
                        emptyCanvas
                    } else {
                        inboxFeed
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

    private var readCount: Int {
        inAppService.appInboxMessages.count - unreadCount
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [
                        Color(red: 0.06, green: 0.07, blue: 0.08),
                        Color(red: 0.09, green: 0.10, blue: 0.12),
                        Color(red: 0.12, green: 0.11, blue: 0.10)
                    ]
                    : [
                        Color(red: 0.95, green: 0.94, blue: 0.91),
                        Color(red: 0.98, green: 0.97, blue: 0.95),
                        Color(red: 0.92, green: 0.93, blue: 0.95)
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.74, green: 0.46, blue: 0.21).opacity(isDarkMode ? 0.18 : 0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: -140, y: -280)

            Circle()
                .fill(Color(red: 0.28, green: 0.48, blue: 0.44).opacity(isDarkMode ? 0.18 : 0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 150, y: -180)
        }
    }

    private var mastheadSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("APP INBOX")
                        .font(.caption2.weight(.bold))
                        .tracking(1.3)
                        .foregroundStyle(secondaryText)

                    Text("Campaign Dispatch")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)

                    Text("Inspect message inventory, trigger inbox samples, and manage read state from one dispatch surface.")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    Task {
                        await refreshInbox()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(accentSoft)
                            .frame(width: 62, height: 62)

                        Image(systemName: "paperplane.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(accent)
                    }
                }
                .buttonStyle(.plain)
                .rotationEffect(.degrees(inAppService.isRefreshingInbox ? 360 : 0))
                .animation(.linear(duration: 0.9), value: inAppService.isRefreshingInbox)
                .disabled(inAppService.isRefreshingInbox)
            }

            HStack(spacing: 10) {
                statusLozenge(title: selectedFilter.title.uppercased())
                statusLozenge(title: unreadCount > 0 ? "UNREAD LIVE" : "ALL CLEAR")
                statusLozenge(title: inAppService.isRefreshingInbox ? "SYNCING" : "READY")
            }
        }
        .padding(18)
        .background(shellFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.18 : 0.06), radius: 14, y: 10)
    }

    private var summaryRail: some View {
        HStack(spacing: 10) {
            InboxSummaryCard(title: "Inventory", value: "\(inAppService.appInboxMessages.count)", caption: "messages", tint: accent, isDarkMode: isDarkMode)
            InboxSummaryCard(title: "Unread", value: "\(unreadCount)", caption: "pending", tint: .orange, isDarkMode: isDarkMode)
            InboxSummaryCard(title: "Read", value: "\(readCount)", caption: "reviewed", tint: .green, isDarkMode: isDarkMode)
        }
    }

    private var commandDeck: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Command Deck")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text("Switch views and fire sample campaigns.")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer(minLength: 0)
            }

            filterSelector
            actionMatrix
        }
        .padding(16)
        .background(shellFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
    }

    private var filterSelector: some View {
        HStack(spacing: 10) {
            ForEach(InboxFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                        selectedFilter = filter
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(filter.title)
                            .font(.subheadline.weight(.bold))
                        Text(filterSubtitle(for: filter))
                            .font(.caption2)
                            .opacity(0.72)
                    }
                    .foregroundStyle(selectedFilter == filter ? selectedText : primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(filterBackground(for: filter), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(selectedFilter == filter ? Color.clear : shellBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionMatrix: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                commandButton(title: "Trigger", subtitle: "single", icon: "plus.bubble.fill", tint: accent) {
                    inAppService.triggerAppInboxMessage()
                }

                commandButton(title: "Carousel", subtitle: "multi-card", icon: "square.stack.3d.forward.dottedline", tint: .orange) {
                    inAppService.triggerCarouselAppInboxMessage()
                }
            }

            HStack(spacing: 10) {
                commandButton(title: "Mark Read", subtitle: "all items", icon: "checkmark.circle.fill", tint: .green, isDisabled: isPerformingBulkAction || inAppService.appInboxMessages.isEmpty) {
                    markAllAsRead()
                }

                commandButton(title: "Clear", subtitle: "delete all", icon: "trash.fill", tint: .red, isDisabled: isPerformingBulkAction || inAppService.appInboxMessages.isEmpty) {
                    clearAllMessages()
                }
            }
        }
    }

    private var inboxFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message Ledger")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text("\(filteredMessages.count) entries in the current view")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }

                Spacer()
            }

            LazyVStack(spacing: 12) {
                ForEach(messageItems) { item in
                    MessageRow(
                        message: item.message,
                        isDarkMode: isDarkMode,
                        accent: accent,
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
    }

    private var emptyCanvas: some View {
        VStack(alignment: .leading, spacing: 18) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(accentSoft)
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "tray.full.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(accent)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text("No campaigns in this lane")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(primaryText)

                Text("Trigger a sample inbox message, or change the filter to inspect another delivery state.")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                commandButton(title: "Trigger", subtitle: "single", icon: "plus.bubble.fill", tint: accent) {
                    inAppService.triggerAppInboxMessage()
                }

                commandButton(title: "Carousel", subtitle: "multi-card", icon: "square.stack.3d.forward.dottedline", tint: .orange) {
                    inAppService.triggerCarouselAppInboxMessage()
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shellFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
    }

    private var messageItems: [InboxMessageListItem] {
        filteredMessages.enumerated().map { index, message in
            let messageId = message.messageId ?? "no-id"
            let stableId = "\(messageId)-\(message.date)-\(index)"
            return InboxMessageListItem(id: stableId, message: message)
        }
    }

    private var shellFill: Color {
        isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.93)
    }

    private var shellBorder: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    private var primaryText: Color {
        isDarkMode ? Color.white.opacity(0.96) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.62) : Color.black.opacity(0.56)
    }

    private var accent: Color {
        isDarkMode ? Color(red: 0.92, green: 0.70, blue: 0.36) : Color(red: 0.66, green: 0.43, blue: 0.14)
    }

    private var accentSoft: Color {
        accent.opacity(isDarkMode ? 0.18 : 0.10)
    }

    private var selectedText: Color {
        isDarkMode ? Color.black.opacity(0.88) : .white
    }

    private func filterBackground(for filter: InboxFilter) -> Color {
        selectedFilter == filter ? accent : (isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
    }

    private func filterSubtitle(for filter: InboxFilter) -> String {
        switch filter {
        case .all:
            return "full inbox"
        case .unread:
            return "needs review"
        case .read:
            return "completed"
        }
    }

    private func statusLozenge(title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(shellBorder, lineWidth: 1)
            )
    }

    private func commandButton(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 34, height: 34)

                    Image(systemName: icon)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                    Text(subtitle)
                        .font(.caption2)
                        .opacity(0.72)
                }

                Spacer(minLength: 0)
            }
            .foregroundStyle(primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(shellBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
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

private struct InboxSummaryCard: View {
    let title: String
    let value: String
    let caption: String
    let tint: Color
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isDarkMode ? Color.white.opacity(0.62) : Color.black.opacity(0.56))

            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(isDarkMode ? Color.white.opacity(0.96) : Color.black.opacity(0.90))

            Text(caption)
                .font(.caption2)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.93), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07), lineWidth: 1)
        )
    }
}

struct MessageRow: View {
    let message: CleverTapInboxMessage
    let isDarkMode: Bool
    let accent: Color
    let onTap: () -> Void
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void

    @State private var showActions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                messageThumb

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.content?.first?.title ?? "Message")
                                .font(.subheadline.weight(message.isRead ? .semibold : .bold))
                                .foregroundStyle(primaryText)
                                .lineLimit(2)

                            Text(message.campaignId ?? "Campaign")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(secondaryText)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 0)

                        if !message.isRead {
                            Circle()
                                .fill(accent)
                                .frame(width: 9, height: 9)
                        }
                    }

                    if let messageText = message.content?.first?.message {
                        Text(messageText)
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                            .lineLimit(3)
                    }
                }
            }

            HStack(spacing: 10) {
                metaTag(relativeDate(from: message.date))
                metaTag(message.isRead ? "Read" : "Unread")

                Spacer()

                Button {
                    showActions.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(secondaryText)
                        .frame(width: 28, height: 28)
                        .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(message.isRead ? cardBorder : accent.opacity(0.45), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    private var primaryText: Color {
        isDarkMode ? Color.white.opacity(0.96) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.62) : Color.black.opacity(0.56)
    }

    private var cardFill: Color {
        isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.93)
    }

    private var cardBorder: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
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
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var placeholderThumb: some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.95), Color(red: 0.28, green: 0.48, blue: 0.44).opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "envelope.fill")
                .foregroundStyle(.white)
                .font(.headline)
        }
    }

    private func metaTag(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(secondaryText)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: Capsule())
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0

    private var contents: [CleverTapInboxMessageContent] {
        message.content ?? []
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        NavigationView {
            ZStack {
                detailBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        detailMasthead
                        detailContentSurface
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Message")
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

    private var detailBackground: some View {
        LinearGradient(
            colors: isDarkMode
                ? [
                    Color(red: 0.06, green: 0.07, blue: 0.08),
                    Color(red: 0.10, green: 0.10, blue: 0.12)
                ]
                : [
                    Color(red: 0.96, green: 0.95, blue: 0.93),
                    Color(red: 0.92, green: 0.93, blue: 0.95)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var detailMasthead: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(accentSoft)
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: "envelope.open.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(accent)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text("MESSAGE DOSSIER")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(secondaryText)

                    Text(message.campaignId ?? (contents.first?.title ?? "Inbox Message"))
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text(contents.count > 1 ? "Carousel campaign with \(contents.count) slides" : "Single campaign message")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                detailMetaPill(message.isRead ? "Read" : "Unread")
                if contents.count > 1 {
                    detailMetaPill("Slide \(currentPage + 1) of \(contents.count)")
                }
            }
        }
        .padding(18)
        .background(shellFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var detailContentSurface: some View {
        VStack(alignment: .leading, spacing: 16) {
            if contents.count > 1 {
                TabView(selection: $currentPage) {
                    ForEach(Array(contents.indices), id: \.self) { index in
                        messageContentCard(contents[index])
                            .tag(index)
                    }
                }
                .frame(height: 420)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            } else if let content = contents.first {
                messageContentCard(content)
            } else {
                Text("No content available for this inbox message.")
                    .font(.body)
                    .foregroundStyle(secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shellFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func messageContentCard(_ content: CleverTapInboxMessageContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let mediaUrl = content.mediaUrl {
                AppAsyncImage(urlString: mediaUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                            .frame(height: 240)
                            .overlay(ProgressView())
                    }
                }
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                if let title = content.title {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(primaryText)
                }

                if let messageText = content.message {
                    Text(messageText)
                        .font(.body)
                        .foregroundColor(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var shellFill: Color {
        isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.93)
    }

    private var shellBorder: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }

    private var primaryText: Color {
        isDarkMode ? Color.white.opacity(0.96) : Color.black.opacity(0.90)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.62) : Color.black.opacity(0.56)
    }

    private var accent: Color {
        isDarkMode ? Color(red: 0.92, green: 0.70, blue: 0.36) : Color(red: 0.66, green: 0.43, blue: 0.14)
    }

    private var accentSoft: Color {
        accent.opacity(isDarkMode ? 0.18 : 0.10)
    }

    private func detailMetaPill(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03), in: Capsule())
    }
}

#Preview {
    NavigationView {
        AppInboxView()
    }
}
