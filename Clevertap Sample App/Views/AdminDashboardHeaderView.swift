import SwiftUI

struct AdminDashboardHeaderView: View {
    let isDarkMode: Bool
    let isSelectionMode: Bool
    let productCount: Int
    let orderCount: Int
    let processingOrderCount: Int
    let visibleCount: Int
    let lowStockCount: Int
    let selectedCount: Int
    let onAdd: () -> Void
    let onToggleSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Admin Dashboard")
                        .font(.title2.weight(.black))
                        .foregroundColor(isDarkMode ? .white : .primary)

                    Text("Products \(productCount) • Orders \(orderCount) • Visible \(visibleCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isDarkMode ? .white.opacity(0.70) : .secondary)
                }

                Spacer(minLength: 0)

                NavigationLink {
                    AdminOrdersView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox")
                        Text("Orders")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color("CleverTapSecondary"), Color("CleverTapPrimary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: dashboardColumns, spacing: 12) {
                metricCard(title: "Products", value: "\(productCount)", tint: Color("CleverTapPrimary"))
                metricCard(title: "Orders", value: "\(orderCount)", tint: Color("CleverTapSecondary"))
                metricCard(title: "Processing", value: "\(processingOrderCount)", tint: .orange)
                metricCard(title: "Selected", value: "\(selectedCount)", tint: .green)
            }

            LazyVGrid(columns: dashboardColumns, spacing: 10) {
                Button(action: onAdd) {
                    actionButton(title: "New Product", systemImage: "plus.circle.fill", tint: Color("CleverTapPrimary"))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AdminAuditLogView()
                } label: {
                    actionButton(title: "Audit Trail", systemImage: "clock.arrow.circlepath", tint: Color("CleverTapSecondary"))
                }
                .buttonStyle(.plain)

                Button(action: onToggleSelection) {
                    actionButton(
                        title: isSelectionMode ? "Exit Bulk" : "Bulk Actions",
                        systemImage: isSelectionMode ? "checkmark.circle.fill" : "checklist",
                        tint: isSelectionMode ? .green : .orange
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AdminOrdersView()
                } label: {
                    actionButton(title: "Manage Orders", systemImage: "shippingbox.fill", tint: Color("CleverTapSecondary"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundCard)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.10) : Color.white.opacity(0.68), lineWidth: 1)
        )
    }

    private var dashboardColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var backgroundCard: some ShapeStyle {
        LinearGradient(
            colors: isDarkMode
                ? [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.04)
                ]
                : [
                    Color.white.opacity(0.78),
                    Color.white.opacity(0.42)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(isDarkMode ? .white.opacity(0.70) : .secondary)

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(isDarkMode ? .white : .primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(isDarkMode ? 0.18 : 0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func actionButton(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(isDarkMode ? .white : .primary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(isDarkMode ? 0.18 : 0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
