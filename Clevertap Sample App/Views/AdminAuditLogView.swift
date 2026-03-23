import SwiftUI

struct AdminAuditLogView: View {
    @StateObject private var auditLogService = AdminAuditLogService()
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var selectedAction = "All"
    @State private var selectedEntity = "All"
    @State private var selectedTimeWindow: AuditTimeWindow = .all

    private var filteredLogs: [AdminAuditEvent] {
        auditLogService.logs.filter { log in
            let matchesAction = selectedAction == "All" || log.action == selectedAction
            let matchesEntity = selectedEntity == "All" || log.entityType == selectedEntity
            let matchesSearch: Bool

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesSearch = true
            } else {
                let query = searchText.lowercased()
                matchesSearch =
                    log.action.lowercased().contains(query) ||
                    log.entityType.lowercased().contains(query) ||
                    log.userEmail.lowercased().contains(query) ||
                    (log.entityId?.lowercased().contains(query) ?? false) ||
                    log.metadata.values.joined(separator: " ").lowercased().contains(query)
            }

            let matchesTime = selectedTimeWindow.contains(log.timestamp)
            return matchesAction && matchesEntity && matchesSearch && matchesTime
        }
    }

    private var availableActions: [String] {
        ["All"] + Array(Set(auditLogService.logs.map(\.action))).sorted()
    }

    private var availableEntities: [String] {
        ["All"] + Array(Set(auditLogService.logs.map(\.entityType))).sorted()
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var surfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.84)
    }

    private var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.94)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.70) : Color.black.opacity(0.56)
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerSection
                    searchSection
                    filterSection

                    if auditLogService.isLoading {
                        loadingState
                    } else if let error = auditLogService.errorMessage {
                        errorState(error)
                    } else if filteredLogs.isEmpty {
                        emptyState
                    } else {
                        logList
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard auditLogService.logs.isEmpty else { return }
            await auditLogService.fetchLogs()
        }
        .refreshable {
            await auditLogService.fetchLogs()
        }
    }
}

private extension AdminAuditLogView {
    var backgroundLayer: some View {
        LinearGradient(
            colors: isDarkMode
                ? [
                    Color(red: 0.05, green: 0.06, blue: 0.09),
                    Color(red: 0.08, green: 0.10, blue: 0.14),
                    Color(red: 0.10, green: 0.10, blue: 0.13)
                ]
                : [
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.92, green: 0.95, blue: 0.98),
                    Color(red: 0.98, green: 0.97, blue: 0.95)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Rectangle()
                .fill(isDarkMode ? Color.black.opacity(0.18) : Color.white.opacity(0.14))
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.24 : 0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: -120, y: -260)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 130, y: -210)
        }
        .ignoresSafeArea()
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY")
                .font(.caption2.weight(.bold))
                .foregroundColor(secondaryText)

            Text("Admin Activity Trail")
                .font(.title2.weight(.bold))
                .foregroundColor(primaryText)

            Text("Review who changed what, when it changed, and which entities were touched.")
                .font(.footnote)
                .foregroundColor(secondaryText)

            HStack(spacing: 10) {
                AdminAuditStatBadge(title: "Events", value: "\(auditLogService.logs.count)")
                AdminAuditStatBadge(title: "Visible", value: "\(filteredLogs.count)")
                AdminAuditStatBadge(title: "Users", value: "\(Set(filteredLogs.map(\.userEmail)).filter { !$0.isEmpty }.count)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surfaceFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.16 : 0.05), radius: 10, y: 6)
    }

    var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(secondaryText)
            TextField("Search by action, entity, email, or metadata", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(primaryText)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(secondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(surfaceFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    var filterSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ],
            spacing: 10
        ) {
            filterMenu(title: "Action", value: normalizedFilterValue(selectedAction), options: availableActions) { option in
                selectedAction = option
            }

            filterMenu(title: "Entity", value: normalizedFilterValue(selectedEntity), options: availableEntities) { option in
                selectedEntity = option
            }

            filterMenu(title: "Window", value: selectedTimeWindow.title, options: AuditTimeWindow.allCases.map(\.title)) { option in
                selectedTimeWindow = AuditTimeWindow.allCases.first(where: { $0.title == option }) ?? .all
            }
        }
    }

    func filterMenu(title: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(normalizedFilterValue(option)) {
                    onSelect(option)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(secondaryText)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(secondaryText)
            }
            .padding(14)
            .background(surfaceFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    var logList: some View {
        LazyVStack(spacing: 14) {
            ForEach(filteredLogs) { log in
                AdminAuditLogCard(log: log)
            }
        }
    }

    var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView("Loading audit trail...")
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text("Unable to load audit trail")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task {
                    await auditLogService.fetchLogs()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("No audit events found")
                .font(.headline)
            Text("Try broadening the filters or perform an admin action to populate the log.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    func normalizedFilterValue(_ value: String) -> String {
        value == "All" ? value : value.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct AdminAuditLogCard: View {
    let log: AdminAuditEvent
    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var surfaceBorder: Color {
        isDarkMode ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    private var primaryText: Color {
        isDarkMode ? .white : Color.black.opacity(0.94)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.70) : Color.black.opacity(0.56)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(log.normalizedAction)
                        .font(.headline)
                        .foregroundColor(primaryText)

                    Text(log.normalizedEntityType)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                }

                Spacer()

                Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 6) {
                if !log.userEmail.isEmpty {
                    auditDetailRow(title: "Admin", value: log.userEmail)
                }

                if let entityId = log.entityId, !entityId.isEmpty {
                    auditDetailRow(title: "Entity ID", value: entityId)
                }

                if !log.metadata.isEmpty {
                    Divider()
                        .padding(.vertical, 2)

                    ForEach(log.metadata.keys.sorted(), id: \.self) { key in
                        if let value = log.metadata[key], !value.isEmpty {
                            auditDetailRow(
                                title: key.replacingOccurrences(of: "_", with: " ").capitalized,
                                value: value
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.82),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.14 : 0.04), radius: 8, y: 4)
    }

    func auditDetailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(secondaryText)
            Text(value)
                .font(.subheadline)
                .foregroundColor(primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AdminAuditStatBadge: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.66) : Color.black.opacity(0.54))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(colorScheme == .dark ? .white : Color.black.opacity(0.92))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

private enum AuditTimeWindow: CaseIterable {
    case all
    case today
    case last7Days
    case last30Days

    var title: String {
        switch self {
        case .all:
            return "All Time"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        }
    }

    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current

        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .last7Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) else { return true }
            return date >= cutoff
        case .last30Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -30, to: Date()) else { return true }
            return date >= cutoff
        }
    }
}
