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

    var body: some View {
        ZStack {
            backgroundLayer

            Circle()
                .fill(Color("CleverTapPrimary").opacity(isDarkMode ? 0.20 : 0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 36)
                .offset(x: -140, y: -320)

            Circle()
                .fill(Color("CleverTapSecondary").opacity(isDarkMode ? 0.18 : 0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 48)
                .offset(x: 160, y: -260)

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
                    Color(.systemBackground),
                    Color(red: 0.08, green: 0.10, blue: 0.14),
                    Color(.systemGroupedBackground)
                ]
                : [
                    Color("CleverTapPrimary").opacity(0.16),
                    Color("CleverTapSecondary").opacity(0.10),
                    Color(.systemBackground),
                    Color(.systemBackground)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AUDIT")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("CleverTapPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())

            Text("Admin Activity Trail")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)

            Text("Review who changed what, when it changed, and which entities were touched.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                AdminAuditStatBadge(title: "Events", value: "\(auditLogService.logs.count)")
                AdminAuditStatBadge(title: "Visible", value: "\(filteredLogs.count)")
                AdminAuditStatBadge(title: "Users", value: "\(Set(filteredLogs.map(\.userEmail)).filter { !$0.isEmpty }.count)")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search by action, entity, email, or metadata", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var filterSection: some View {
        VStack(spacing: 12) {
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
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(log.normalizedAction)
                        .font(.headline)
                        .foregroundColor(.primary)

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
                    .foregroundColor(.secondary)
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
            isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.76),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.16) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    func auditDetailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct AdminAuditStatBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
