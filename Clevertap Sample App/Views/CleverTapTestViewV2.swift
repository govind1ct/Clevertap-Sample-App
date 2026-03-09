import SwiftUI
import CleverTapSDK
import UIKit

struct CleverTapTestViewV2: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: Tab = .actions
    @State private var searchText = ""
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var revealContent = false
    @State private var contentTransitionID = UUID()
    @Namespace private var tabAnimation
    @State private var customEventName = ""
    @State private var customEventProps: [EventPropInput] = [EventPropInput()]
    @State private var presetNameInput = ""
    @State private var presetRefreshDiagnostics = true
    @State private var presetPushAction: PresetPushAction = .none
    @State private var savedPresets: [SavedScenarioPreset] = []
    @State private var selectedTrace: NSETraceItem?
    @State private var traceSearchText = ""
    @State private var traceSortNewestFirst = true
    @State private var selectedTraceFilter: TraceFilter = .all
    @State private var timerPushEventMode: TimerPushMode = .allAliases
    @State private var showUsageGuide = false

    private enum Tab: String, CaseIterable {
        case actions = "Actions"
        case debug = "Debug"
        case activity = "Activity"
    }

    private enum SharedPushIdentityConfig {
        static let appGroupID = "group.com.govind.clevertap-sample-app"
        static let lastImpressionDebugKey = "ct_last_impression_debug"
        static let traceLogsKey = "ct_nse_trace_logs"
        static let savedPresetsKey = "ct_test_lab_v2_saved_presets"
    }

    private struct QuickAction: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let action: () -> Void
    }

    private struct ScenarioAction: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let action: () -> Void
    }

    private struct NSETraceItem: Identifiable {
        let id = UUID()
        let event: String
        let timestamp: String
        let requestID: String
        let wzrkID: String
        let profileID: String
    }

    private struct EventPropInput: Identifiable {
        let id = UUID()
        var key: String = ""
        var value: String = ""
    }

    private enum TraceFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case viewRecorded = "view recorded"
        case sdkNil = "sdk nil"
        case identityMismatch = "identity mismatch"

        var id: String { rawValue }
    }

    private enum PresetPushAction: String, CaseIterable, Identifiable, Codable {
        case none
        case basicPush
        case richPush
        case timerPush

        var id: String { rawValue }

        var title: String {
            switch self {
            case .none: return "No Push Action"
            case .basicPush: return "Trigger Basic Push"
            case .richPush: return "Trigger Rich Push"
            case .timerPush: return "Trigger Timer Push"
            }
        }
    }

    private enum TimerPushMode: String, CaseIterable, Identifiable {
        case allAliases
        case primary
        case legacy
        case delayFlow

        var id: String { rawValue }

        var title: String {
            switch self {
            case .allAliases: return "All Aliases"
            case .primary: return "Primary"
            case .legacy: return "Legacy"
            case .delayFlow: return "Delay Flow"
            }
        }

        var serviceMode: CleverTapInAppService.TimerPushEventMode {
            switch self {
            case .allAliases: return .allAliases
            case .primary: return .primary
            case .legacy: return .legacy
            case .delayFlow: return .delayFlow
            }
        }
    }

    private struct SavedPresetProp: Codable {
        let key: String
        let value: String
    }

    private struct SavedScenarioPreset: Identifiable, Codable {
        let id: UUID
        let name: String
        let eventName: String
        let props: [SavedPresetProp]
        let shouldRefreshDiagnostics: Bool
        let pushAction: PresetPushAction
    }

    private enum InsightSeverity {
        case critical
        case warning
        case info

        var color: Color {
            switch self {
            case .critical: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }

        var label: String {
            switch self {
            case .critical: return "Critical"
            case .warning: return "Warning"
            case .info: return "Info"
            }
        }
    }

    private struct TraceInsightItem: Identifiable {
        let id = UUID()
        let severity: InsightSeverity
        let title: String
        let matches: Int
        let likelyCause: String
        let recommendedFix: String
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var chromeGradient: [Color] {
        if isDarkMode {
            return [
                Color(red: 0.04, green: 0.06, blue: 0.10),
                Color(red: 0.07, green: 0.08, blue: 0.14),
                Color(red: 0.10, green: 0.08, blue: 0.08)
            ]
        }
        return [
            Color(red: 0.98, green: 0.97, blue: 0.95),
            Color(red: 0.96, green: 0.93, blue: 0.90),
            Color(red: 0.93, green: 0.96, blue: 0.98)
        ]
    }

    private var accentStart: Color {
        isDarkMode ? Color(red: 1.00, green: 0.45, blue: 0.20) : Color(red: 0.92, green: 0.30, blue: 0.10)
    }

    private var accentEnd: Color {
        isDarkMode ? Color(red: 0.96, green: 0.72, blue: 0.20) : Color(red: 0.94, green: 0.55, blue: 0.20)
    }

    private var coolAccent: Color {
        isDarkMode ? Color(red: 0.22, green: 0.88, blue: 0.95) : Color(red: 0.08, green: 0.63, blue: 0.78)
    }

    private var panelFill: Color {
        isDarkMode ? Color.white.opacity(0.06) : Color.white.opacity(0.76)
    }

    private var panelStroke: Color {
        isDarkMode ? Color.white.opacity(0.14) : Color.black.opacity(0.08)
    }

    private var primaryText: Color {
        isDarkMode ? Color.white.opacity(0.94) : Color.black.opacity(0.86)
    }

    private var secondaryText: Color {
        isDarkMode ? Color.white.opacity(0.70) : Color.black.opacity(0.60)
    }

    private var statusColor: Color {
        inAppService.connectionStatus.lowercased().contains("ready") ? .green : .orange
    }

    private var nseLastReason: String {
        guard let defaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID),
              let payload = defaults.dictionary(forKey: SharedPushIdentityConfig.lastImpressionDebugKey),
              let reason = payload["reason"] as? String,
              !reason.isEmpty else {
            return "Not Set"
        }
        return reason
    }

    private var nseTraceCount: Int {
        guard let defaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return 0
        }
        return (defaults.array(forKey: SharedPushIdentityConfig.traceLogsKey) as? [[String: String]] ?? []).count
    }

    private var recentNSETraces: [NSETraceItem] {
        guard let defaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID),
              let rawLogs = defaults.array(forKey: SharedPushIdentityConfig.traceLogsKey) as? [[String: String]] else {
            return []
        }

        return rawLogs.suffix(6).reversed().map { log in
            NSETraceItem(
                event: log["event"] ?? "unknown",
                timestamp: log["timestamp"] ?? "-",
                requestID: log["request_id"] ?? "-",
                wzrkID: log["wzrk_id"] ?? "-",
                profileID: (log["ct_profile_id"] ?? "").isEmpty ? "-" : (log["ct_profile_id"] ?? "-")
            )
        }
    }

    private var formattedLastRefresh: String {
        guard let refreshDate = inAppService.lastDiagnosticsRefresh else {
            return "Not Refreshed"
        }
        return refreshDate.formatted(date: .abbreviated, time: .shortened)
    }

    private var quickActions: [QuickAction] {
        [
            QuickAction(
                title: "Basic Push",
                subtitle: "Trigger standard campaign",
                icon: "paperplane.fill",
                action: {
                    inAppService.triggerPushNotification()
                    showMessage("Triggered Basic Push event")
                }
            ),
            QuickAction(
                title: "Rich Push",
                subtitle: "Trigger media campaign",
                icon: "photo.fill",
                action: {
                    inAppService.triggerRichPushNotification()
                    showMessage("Triggered Rich Push event")
                }
            ),
            QuickAction(
                title: "Timer Push",
                subtitle: "Trigger delayed campaign",
                icon: "timer",
                action: {
                    inAppService.triggerTimerPushNotification(mode: timerPushEventMode.serviceMode)
                    showMessage("Triggered Timer Push event")
                }
            ),
            QuickAction(
                title: "Refresh Diagnostics",
                subtitle: "Refresh SDK + push state",
                icon: "waveform.path.ecg",
                action: {
                    inAppService.refreshDiagnostics()
                    showMessage("Diagnostics refreshed")
                }
            )
        ]
    }

    private var scenarioActions: [ScenarioAction] {
        [
            ScenarioAction(
                title: "Push Health",
                subtitle: "Refresh + basic push",
                icon: "stethoscope",
                action: {
                    inAppService.refreshDiagnostics()
                    inAppService.triggerPushNotification()
                    showMessage("Push health scenario completed")
                }
            ),
            ScenarioAction(
                title: "Rich Media",
                subtitle: "Refresh + rich push",
                icon: "photo.stack",
                action: {
                    inAppService.refreshDiagnostics()
                    inAppService.triggerRichPushNotification()
                    showMessage("Rich media scenario completed")
                }
            ),
            ScenarioAction(
                title: "Delay Flow",
                subtitle: "Refresh + timer push",
                icon: "clock.arrow.2.circlepath",
                action: {
                    inAppService.refreshDiagnostics()
                    inAppService.triggerTimerPushNotification(mode: timerPushEventMode.serviceMode)
                    showMessage("Delay flow scenario completed")
                }
            )
        ]
    }

    private var filteredActions: [QuickAction] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return quickActions }
        return quickActions.filter {
            $0.title.lowercased().contains(query) || $0.subtitle.lowercased().contains(query)
        }
    }

    private var filteredNSETraces: [NSETraceItem] {
        let query = traceSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filteredByChip = recentNSETraces.filter { trace in
            switch selectedTraceFilter {
            case .all:
                return true
            case .viewRecorded:
                return trace.event.lowercased().contains("view recorded")
            case .sdkNil:
                return trace.event.lowercased().contains("sdk nil")
            case .identityMismatch:
                return trace.event.lowercased().contains("identity mismatch") || trace.profileID == "-"
            }
        }

        let filteredBySearch: [NSETraceItem]
        if query.isEmpty {
            filteredBySearch = filteredByChip
        } else {
            filteredBySearch = filteredByChip.filter { trace in
                trace.event.lowercased().contains(query) ||
                trace.requestID.lowercased().contains(query) ||
                trace.wzrkID.lowercased().contains(query) ||
                trace.profileID.lowercased().contains(query) ||
                trace.timestamp.lowercased().contains(query)
            }
        }

        if traceSortNewestFirst {
            return filteredBySearch
        }
        return Array(filteredBySearch.reversed())
    }

    private var traceInsights: [TraceInsightItem] {
        let traces = recentNSETraces
        let reason = nseLastReason.lowercased()

        let sdkNilCount = traces.filter { $0.event.lowercased().contains("sdk nil") }.count
        let identityMismatchCount = traces.filter {
            let event = $0.event.lowercased()
            return event.contains("identity mismatch") || $0.profileID == "-"
        }.count
        let missingWzrkCount = traces.filter { $0.wzrkID == "-" || $0.wzrkID.lowercased() == "unknown" }.count
        let viewedCount = traces.filter { $0.event.lowercased().contains("view recorded") }.count

        var items: [TraceInsightItem] = []

        if sdkNilCount > 0 || reason.contains("sdk nil") || reason.contains("sdk_nil") {
            items.append(
                TraceInsightItem(
                    severity: .critical,
                    title: "SDK unavailable in NSE path",
                    matches: max(sdkNilCount, 1),
                    likelyCause: "Notification Service Extension could not access CleverTap shared instance or app group context in time.",
                    recommendedFix: "Verify NSE target embeds CleverTap, app group is identical across app/NSE/NCE, and extension starts before timeout."
                )
            )
        }

        if identityMismatchCount > 0 || reason.contains("identity mismatch") {
            items.append(
                TraceInsightItem(
                    severity: .warning,
                    title: "Identity mismatch risk",
                    matches: max(identityMismatchCount, 1),
                    likelyCause: "NSE payload profile identifier does not align with app-side logged-in identity or shared defaults data is stale.",
                    recommendedFix: "Log out/in once, re-sync identity to app group, and validate `ct_identity` in shared defaults before sending campaign."
                )
            )
        }

        if missingWzrkCount > 0 {
            items.append(
                TraceInsightItem(
                    severity: .warning,
                    title: "Missing campaign identifiers",
                    matches: missingWzrkCount,
                    likelyCause: "Push payload is missing CleverTap campaign metadata (`wzrk_id`) or not recognized as CleverTap payload.",
                    recommendedFix: "Send via CleverTap campaign and verify payload includes `wzrk_id`/CleverTap keys in APNS debugger."
                )
            )
        }

        if viewedCount > 0 && items.isEmpty {
            items.append(
                TraceInsightItem(
                    severity: .info,
                    title: "Impression path healthy",
                    matches: viewedCount,
                    likelyCause: "Recent traces indicate `view recorded` events are being captured.",
                    recommendedFix: "Validate click/open events next to complete end-to-end push pipeline checks."
                )
            )
        }

        return items
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: chromeGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            Circle()
                .fill(accentStart.opacity(isDarkMode ? 0.20 : 0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: -150, y: -360)

            Circle()
                .fill(coolAccent.opacity(isDarkMode ? 0.16 : 0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 48)
                .offset(x: 170, y: -270)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                        .opacity(revealContent ? 1 : 0)
                        .offset(y: revealContent ? 0 : 8)
                        .animation(.easeOut(duration: 0.28), value: revealContent)

                    tabStrip
                        .opacity(revealContent ? 1 : 0)
                        .offset(y: revealContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.30).delay(0.06), value: revealContent)

                    Group {
                        switch selectedTab {
                        case .actions:
                            actionsSection
                        case .debug:
                            debugSection
                        case .activity:
                            activitySection
                        }
                    }
                    .id(contentTransitionID)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        )
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 96)
            }

            if showToast {
                Text(toastMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.84), in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("CleverTap Test Lab V2")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !revealContent {
                revealContent = true
            }
            if savedPresets.isEmpty {
                loadSavedPresets()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                inAppService.refreshDiagnostics()
            }
        }
        .onChange(of: selectedTab) { _, _ in
            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                contentTransitionID = UUID()
            }
        }
        .sheet(item: $selectedTrace) { trace in
            traceDetailSheet(trace: trace)
        }
        .sheet(isPresented: $showUsageGuide) {
            usageGuideSheet
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("QA CONSOLE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(coolAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(coolAccent.opacity(0.14), in: Capsule())

                    Text("Test Lab 2.0")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [primaryText, primaryText.opacity(0.70)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Revamped controls for campaign QA, push diagnostics, and live impression traces.")
                        .font(.subheadline)
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accentStart.opacity(0.26), accentEnd.opacity(0.20)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentStart, accentEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }

            HStack(spacing: 10) {
                metricPill(title: "Push", value: "\(inAppService.pushNotificationCount)", icon: "paperplane.fill")
                metricPill(title: "Inbox", value: "\(inAppService.appInboxCount)", icon: "tray.full.fill")
                metricPill(title: "NSE", value: "\(nseTraceCount)", icon: "waveform.path.ecg")
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(inAppService.connectionStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
                Spacer()
                Button {
                    showUsageGuide = true
                } label: {
                    Label("How to Use", systemImage: "questionmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(coolAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(coolAccent.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private var tabStrip: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selectedTab == tab ? Color.white : primaryText)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [accentStart, accentEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "tab-bg", in: tabAnimation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private var actionsSection: some View {
        VStack(spacing: 14) {
            sectionHeader("Scenarios", subtitle: "Run grouped QA flows")

            HStack(spacing: 8) {
                Text("Timer Event Mode")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(secondaryText)
                Spacer()
                Picker("Timer Event Mode", selection: $timerPushEventMode) {
                    ForEach(TimerPushMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            )

            Text("How it works: this controls which timer event name is fired when you run Timer Push/Delay Flow. Use `All Aliases` for compatibility; use `Primary`, `Legacy`, or `Delay Flow` when validating a specific campaign trigger in CleverTap dashboard.")
                .font(.caption2)
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(scenarioActions.enumerated()), id: \.element.id) { index, scenario in
                        Button {
                            scenario.action()
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Image(systemName: scenario.icon)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(accentStart)

                                Text(scenario.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(primaryText)

                                Text(scenario.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(secondaryText)
                                    .lineLimit(2)
                            }
                            .padding(13)
                            .frame(width: 206, alignment: .leading)
                            .background(panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(panelStroke, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(revealContent ? 1 : 0)
                        .offset(y: revealContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.36).delay(Double(index) * 0.05), value: revealContent)
                    }
                }
            }

            sectionHeader("Actions", subtitle: "\(filteredActions.count) available")

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(secondaryText)
                TextField("Search action", text: $searchText)
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
                    Button(action: action.action) {
                        VStack(alignment: .leading, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(coolAccent.opacity(0.18))
                                    .frame(width: 34, height: 34)

                                Image(systemName: action.icon)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(coolAccent)
                            }

                            Text(action.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(primaryText)
                                .lineLimit(1)

                            Text(action.subtitle)
                                .font(.caption)
                                .foregroundStyle(secondaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer(minLength: 0)

                            HStack(spacing: 4) {
                                Text("Run")
                                    .font(.caption.weight(.semibold))
                                Image(systemName: "arrow.right")
                                    .font(.caption2.weight(.bold))
                            }
                            .foregroundStyle(accentStart)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                        .padding(14)
                        .background(panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(panelStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(revealContent ? 1 : 0)
                    .offset(y: revealContent ? 0 : 12)
                    .animation(.easeOut(duration: 0.34).delay(Double(index) * 0.03), value: revealContent)
                }
            }

            sectionHeader("Event Payload Editor", subtitle: "Create custom event + dynamic props")

            VStack(spacing: 10) {
                TextField("Event name (e.g. QA Custom Event)", text: $customEventName)
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(panelStroke, lineWidth: 1)
                    )

                ForEach($customEventProps) { $prop in
                    HStack(spacing: 8) {
                        TextField("Key", text: $prop.key)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(panelFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(panelStroke, lineWidth: 1)
                            )

                        TextField("Value", text: $prop.value)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(panelFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(panelStroke, lineWidth: 1)
                            )

                        if customEventProps.count > 1 {
                            Button {
                                customEventProps.removeAll { $0.id == prop.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        customEventProps.append(EventPropInput())
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Property")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(coolAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(coolAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(coolAccent.opacity(0.28), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        triggerCustomEvent()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                            Text("Trigger Event")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [accentStart, accentEnd], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(panelFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            )

            sectionHeader("Scenario Runner", subtitle: "Save and replay test flows")

            VStack(spacing: 10) {
                TextField("Preset name (e.g. Push QA Smoke)", text: $presetNameInput)
                    .font(.subheadline)
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(panelStroke, lineWidth: 1)
                    )

                Toggle("Refresh diagnostics before run", isOn: $presetRefreshDiagnostics)
                    .font(.caption.weight(.semibold))
                    .tint(accentStart)
                    .padding(.horizontal, 4)

                Picker("Push action", selection: $presetPushAction) {
                    ForEach(PresetPushAction.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    saveCurrentEditorAsPreset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Current Flow as Preset")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(colors: [accentStart, accentEnd], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                if savedPresets.isEmpty {
                    Text("No saved presets yet")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                } else {
                    ForEach(savedPresets) { preset in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(preset.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(primaryText)
                                Spacer()
                                Text(preset.pushAction.title)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(secondaryText)
                            }

                            Text("Event: \(preset.eventName) • Props: \(preset.props.count)")
                                .font(.caption)
                                .foregroundStyle(secondaryText)

                            HStack(spacing: 8) {
                                Button {
                                    runPreset(preset)
                                } label: {
                                    Label("Run", systemImage: "play.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(accentStart, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    loadPresetIntoEditor(preset)
                                } label: {
                                    Label("Load", systemImage: "arrow.down.doc")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(coolAccent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(coolAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deletePreset(preset)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(panelStroke, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(12)
            .background(panelFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(panelStroke, lineWidth: 1)
            )

            NavigationLink {
                CleverTapTestView()
            } label: {
                HStack {
                    Text("Open Full Test Lab (V1)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .foregroundStyle(primaryText)
                .padding(14)
                .background(coolAccent.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(14)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private var debugSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Debug Core", subtitle: "SDK, permission, and NSE diagnostics")

            HStack(spacing: 10) {
                compactCard(title: "SDK", value: inAppService.connectionStatus)
                compactCard(title: "Permission", value: inAppService.pushPermissionStatus)
            }

            HStack(spacing: 10) {
                compactCard(title: "NSE Reason", value: nseLastReason)
                compactCard(title: "Trace Count", value: "\(nseTraceCount)")
            }

            debugRow(title: "CleverTap ID", value: CleverTap.sharedInstance()?.profileGetID() ?? "Not Set")
            debugRow(title: "Last Refresh", value: formattedLastRefresh)

            HStack(spacing: 10) {
                debugActionButton(
                    title: "Copy Snapshot",
                    icon: "doc.on.doc",
                    tint: coolAccent
                ) {
                    copyToClipboard(buildDebugSnapshot())
                    showMessage("Debug snapshot copied")
                }

                debugActionButton(
                    title: "Clear NSE Traces",
                    icon: "trash",
                    tint: .red
                ) {
                    clearNSETraceLogs()
                    showMessage("NSE traces cleared")
                }
            }

            HStack(spacing: 10) {
                debugActionButton(
                    title: "Request Push Permission",
                    icon: "bell.badge",
                    tint: accentStart
                ) {
                    NotificationDelegate.shared.requestNotificationPermissions()
                    showMessage("Permission request triggered")
                }

                debugActionButton(
                    title: "Open Settings",
                    icon: "gearshape",
                    tint: .orange
                ) {
                    openAppSettings()
                }
            }

            if !traceInsights.isEmpty {
                sectionHeader("Trace Insights", subtitle: "Auto diagnosis from latest traces")

                ForEach(traceInsights) { insight in
                    traceInsightCard(insight)
                }
            }

            if !recentNSETraces.isEmpty {
                sectionHeader("NSE Trace Timeline", subtitle: "\(filteredNSETraces.count) filtered")

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(secondaryText)
                    TextField("Search event / request / wzrk / profile", text: $traceSearchText)
                        .font(.caption)
                        .foregroundStyle(primaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(panelStroke, lineWidth: 1)
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TraceFilter.allCases) { filter in
                            Button {
                                selectedTraceFilter = filter
                            } label: {
                                Text(filter.rawValue.capitalized)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(selectedTraceFilter == filter ? .white : primaryText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedTraceFilter == filter
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [accentStart, accentEnd],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                          )
                                        : AnyShapeStyle(panelFill),
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(selectedTraceFilter == filter ? Color.clear : panelStroke, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        traceSortNewestFirst.toggle()
                    } label: {
                        Label(
                            traceSortNewestFirst ? "Newest First" : "Oldest First",
                            systemImage: "arrow.up.arrow.down"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(coolAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(coolAccent.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        copyToClipboard(filteredTracePayload())
                        showMessage("Filtered traces copied")
                    } label: {
                        Label("Copy Filtered", systemImage: "doc.on.doc")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(accentStart, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                ForEach(filteredNSETraces) { trace in
                    Button {
                        selectedTrace = trace
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(trace.event)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(accentStart)
                                Spacer()
                                Text(trace.timestamp)
                                    .font(.caption2)
                                    .foregroundStyle(secondaryText)
                                    .lineLimit(1)
                            }

                            Text("req: \(trace.requestID) | wzrk: \(trace.wzrkID)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(secondaryText)
                                .lineLimit(1)

                            HStack {
                                Text("pid: \(trace.profileID)")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(secondaryText)
                                    .lineLimit(1)
                                Spacer()
                                Label("Details", systemImage: "arrow.up.right.circle")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(coolAccent)
                            }
                        }
                        .padding(10)
                        .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(panelStroke, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                inAppService.refreshDiagnostics()
                showMessage("Debug refreshed")
            } label: {
                Text("Refresh Debug")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [accentStart, accentEnd], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private var activitySection: some View {
        VStack(spacing: 12) {
            sectionHeader("Run Activity", subtitle: "recent trigger and delivery logs")

            HStack(spacing: 10) {
                compactCard(title: "Total Logs", value: "\(inAppService.receivedNotifications.count)")

                Button {
                    inAppService.clearInAppHistory()
                    showMessage("Activity cleared")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            Button {
                copyToClipboard(inAppService.exportLogs())
                showMessage("Activity export copied")
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.on.square")
                    Text("Copy Activity Export")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
                .padding(12)
                .background(panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(panelStroke, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if inAppService.receivedNotifications.isEmpty {
                Text("No activity yet")
                    .font(.subheadline)
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(inAppService.receivedNotifications.prefix(15)) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.eventName)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(primaryText)
                                .lineLimit(1)

                            Spacer()

                            Text(log.status.displayText)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(log.status.color.opacity(0.14), in: Capsule())
                                .foregroundStyle(log.status.color)
                        }

                        HStack(spacing: 8) {
                            Text(log.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption2)
                            Text("payload: \(log.payload.keys.count) keys")
                                .font(.caption2)
                        }
                        .foregroundStyle(secondaryText)
                    }
                    .padding(10)
                    .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(panelStroke, lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(primaryText)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryText)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(primaryText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func debugRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryText)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.semibold))
            Text(value)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(coolAccent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(coolAccent.opacity(0.14), in: Capsule())
    }

    private var usageGuideSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: chromeGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TEST LAB V2 GUIDE")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(coolAccent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(coolAccent.opacity(0.14), in: Capsule())

                            Text("How to use Event Payload Editor + Scenario Runner")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(primaryText)

                            Text("Use this flow for repeatable QA validation and campaign trigger checks.")
                                .font(.subheadline)
                                .foregroundStyle(secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(panelFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(panelStroke, lineWidth: 1)
                        )

                        guideSectionCard(
                            title: "Event Payload Editor",
                            subtitle: "Create and trigger a custom CleverTap event",
                            icon: "slider.horizontal.3"
                        ) {
                            guideStep(1, "Enter event name", "Example: `QA_Custom_Event`")
                            guideStep(2, "Add properties", "Tap `Add Property` and fill key/value pairs")
                            guideStep(3, "Trigger event", "Tap `Trigger Event` to send event to CleverTap")
                            guideStep(4, "Validate output", "Open `Activity` tab and confirm event log entry")
                        }

                        guideSectionCard(
                            title: "Scenario Runner",
                            subtitle: "Save and replay complete test flows",
                            icon: "play.rectangle.fill"
                        ) {
                            guideStep(1, "Prepare editor values", "Set event name + properties first")
                            guideStep(2, "Configure runner", "Set preset name, diagnostics toggle, push action")
                            guideStep(3, "Save preset", "Tap `Save Current Flow as Preset`")
                            guideStep(4, "Run preset", "Tap `Run` to execute event + optional push action")
                            guideStep(5, "Reuse preset", "Use `Load` to edit and `Delete` to remove")
                        }

                        guideSectionCard(
                            title: "Timer Event Mode",
                            subtitle: "Use the right trigger name for delay flow campaigns",
                            icon: "timer"
                        ) {
                            guideStep(1, "All Aliases", "Best default for compatibility")
                            guideStep(2, "Primary", "Fires `Trigger_Timer_Push_Notification` only")
                            guideStep(3, "Legacy", "Fires `Trigger_Timer_Push` only")
                            guideStep(4, "Delay Flow", "Fires `Delay_Flow_Trigger` only")
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showUsageGuide = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func guideSectionCard<Content: View>(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(coolAccent.opacity(0.18))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(coolAccent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primaryText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
                Spacer()
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func guideStep(_ number: Int, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentStart)
                .frame(width: 16, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primaryText)
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private func traceInsightCard(_ insight: TraceInsightItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(primaryText)
                Spacer()
                Text("\(insight.severity.label) • \(insight.matches)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(insight.severity.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.severity.color.opacity(0.14), in: Capsule())
            }

            Text("Likely cause: \(insight.likelyCause)")
                .font(.caption)
                .foregroundStyle(secondaryText)

            Text("Suggested fix: \(insight.recommendedFix)")
                .font(.caption)
                .foregroundStyle(primaryText)
        }
        .padding(10)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func showMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation {
                showToast = false
            }
        }
    }

    private func triggerCustomEvent() {
        let eventName = customEventName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !eventName.isEmpty else {
            showMessage("Enter an event name")
            return
        }

        let payload = customEventPayload
        CleverTap.sharedInstance()?.recordEvent(eventName, withProps: payload)

        inAppService.addNotificationLog(
            eventName: "Custom Event Triggered",
            payload: [
                "event_name": eventName,
                "props_count": payload.count,
                "props": payload
            ],
            status: .triggered
        )

        showMessage("Triggered \(eventName)")
    }

    private func saveCurrentEditorAsPreset() {
        let name = presetNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let eventName = customEventName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showMessage("Enter a preset name")
            return
        }
        guard !eventName.isEmpty else {
            showMessage("Set event name before saving")
            return
        }

        let props = customEventProps.compactMap { item -> SavedPresetProp? in
            let key = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return nil }
            return SavedPresetProp(key: key, value: item.value.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let preset = SavedScenarioPreset(
            id: UUID(),
            name: name,
            eventName: eventName,
            props: props,
            shouldRefreshDiagnostics: presetRefreshDiagnostics,
            pushAction: presetPushAction
        )

        savedPresets.insert(preset, at: 0)
        persistSavedPresets()
        showMessage("Saved preset \(name)")
    }

    private func runPreset(_ preset: SavedScenarioPreset) {
        if preset.shouldRefreshDiagnostics {
            inAppService.refreshDiagnostics()
        }

        var payload: [String: Any] = [:]
        for prop in preset.props {
            payload[prop.key] = parseEventValue(prop.value)
        }

        CleverTap.sharedInstance()?.recordEvent(preset.eventName, withProps: payload)
        executePresetPushAction(preset.pushAction)

        inAppService.addNotificationLog(
            eventName: "Preset Scenario Run",
            payload: [
                "preset_name": preset.name,
                "event_name": preset.eventName,
                "props_count": payload.count,
                "push_action": preset.pushAction.rawValue,
                "refresh_diagnostics": preset.shouldRefreshDiagnostics
            ],
            status: .triggered
        )

        showMessage("Ran preset \(preset.name)")
    }

    private func executePresetPushAction(_ action: PresetPushAction) {
        switch action {
        case .none:
            break
        case .basicPush:
            inAppService.triggerPushNotification()
        case .richPush:
            inAppService.triggerRichPushNotification()
        case .timerPush:
            inAppService.triggerTimerPushNotification(mode: timerPushEventMode.serviceMode)
        }
    }

    private func loadPresetIntoEditor(_ preset: SavedScenarioPreset) {
        presetNameInput = preset.name
        customEventName = preset.eventName
        customEventProps = preset.props.map { SavedProp in
            EventPropInput(key: SavedProp.key, value: SavedProp.value)
        }
        if customEventProps.isEmpty {
            customEventProps = [EventPropInput()]
        }
        presetRefreshDiagnostics = preset.shouldRefreshDiagnostics
        presetPushAction = preset.pushAction
        showMessage("Loaded preset \(preset.name)")
    }

    private func deletePreset(_ preset: SavedScenarioPreset) {
        savedPresets.removeAll { $0.id == preset.id }
        persistSavedPresets()
        showMessage("Deleted preset \(preset.name)")
    }

    private func loadSavedPresets() {
        guard let data = UserDefaults.standard.data(forKey: SharedPushIdentityConfig.savedPresetsKey),
              let presets = try? JSONDecoder().decode([SavedScenarioPreset].self, from: data) else {
            return
        }
        savedPresets = presets
    }

    private func persistSavedPresets() {
        guard let data = try? JSONEncoder().encode(savedPresets) else { return }
        UserDefaults.standard.set(data, forKey: SharedPushIdentityConfig.savedPresetsKey)
    }

    private var customEventPayload: [String: Any] {
        var props: [String: Any] = [:]
        for item in customEventProps {
            let key = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            let rawValue = item.value.trimmingCharacters(in: .whitespacesAndNewlines)
            props[key] = parseEventValue(rawValue)
        }
        return props
    }

    private func parseEventValue(_ raw: String) -> Any {
        if raw.caseInsensitiveCompare("true") == .orderedSame { return true }
        if raw.caseInsensitiveCompare("false") == .orderedSame { return false }
        if let intValue = Int(raw) { return intValue }
        if let doubleValue = Double(raw) { return doubleValue }
        return raw
    }

    private func buildDebugSnapshot() -> String {
        let profileID = CleverTap.sharedInstance()?.profileGetID() ?? "Not Set"
        let traceDump = recentNSETraces.enumerated().map { index, trace in
            "\(index + 1). \(trace.timestamp) | \(trace.event) | req=\(trace.requestID) | wzrk=\(trace.wzrkID) | pid=\(trace.profileID)"
        }.joined(separator: "\n")

        return """
        CleverTap Test Lab V2 Debug Snapshot
        Time: \(Date().formatted(date: .abbreviated, time: .standard))
        SDK Status: \(inAppService.connectionStatus)
        Push Permission: \(inAppService.pushPermissionStatus)
        CleverTap ID: \(profileID)
        NSE Reason: \(nseLastReason)
        NSE Trace Count: \(nseTraceCount)
        Last Refresh: \(formattedLastRefresh)

        Recent NSE Traces:
        \(traceDump.isEmpty ? "No recent traces" : traceDump)
        """
    }

    private func clearNSETraceLogs() {
        guard let defaults = UserDefaults(suiteName: SharedPushIdentityConfig.appGroupID) else {
            return
        }
        defaults.removeObject(forKey: SharedPushIdentityConfig.traceLogsKey)
    }

    private func copyToClipboard(_ value: String) {
        UIPasteboard.general.string = value
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            showMessage("Unable to open settings")
            return
        }

        guard UIApplication.shared.canOpenURL(settingsURL) else {
            showMessage("Settings URL unavailable")
            return
        }

        UIApplication.shared.open(settingsURL)
        showMessage("Opened app settings")
    }

    private func debugActionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func filteredTracePayload() -> String {
        if filteredNSETraces.isEmpty {
            return "No filtered traces"
        }

        return filteredNSETraces.enumerated().map { index, trace in
            """
            \(index + 1). \(trace.timestamp)
            event: \(trace.event)
            req: \(trace.requestID)
            wzrk: \(trace.wzrkID)
            pid: \(trace.profileID)
            """
        }.joined(separator: "\n\n")
    }

    @ViewBuilder
    private func traceDetailSheet(trace: NSETraceItem) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("NSE Trace Detail", subtitle: "Deep inspection for request identity mapping")

                traceDetailRow(title: "Event", value: trace.event)
                traceDetailRow(title: "Timestamp", value: trace.timestamp)
                traceDetailRow(title: "Request ID", value: trace.requestID)
                traceDetailRow(title: "WZRK ID", value: trace.wzrkID)
                traceDetailRow(title: "Profile ID", value: trace.profileID)

                Button {
                    copyToClipboard(traceCopyPayload(trace))
                    showMessage("Trace copied")
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy This Trace")
                        Spacer()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(
                        LinearGradient(colors: [accentStart, accentEnd], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle("Trace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedTrace = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func traceDetailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryText)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
    }

    private func traceCopyPayload(_ trace: NSETraceItem) -> String {
        """
        NSE Trace
        Event: \(trace.event)
        Timestamp: \(trace.timestamp)
        Request ID: \(trace.requestID)
        WZRK ID: \(trace.wzrkID)
        Profile ID: \(trace.profileID)
        """
    }
}

#Preview {
    NavigationStack {
        CleverTapTestViewV2()
    }
}
