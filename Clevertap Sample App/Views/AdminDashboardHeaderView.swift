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

    private var surfaceFill: Color {
        isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.84)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CONTROL CENTER")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(secondaryText)

                    Text("Admin")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primaryText)

                    Text("Catalog, orders, and audit in one place.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
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

            HStack(spacing: 8) {
                quickChip(title: "\(productCount) products")
                quickChip(title: "\(orderCount) orders")
                quickChip(title: "\(visibleCount) visible")
            }

            LazyVGrid(columns: dashboardColumns, spacing: 12) {
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
                    actionButton(title: "Orders", systemImage: "shippingbox.fill", tint: Color("CleverTapSecondary"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.16 : 0.05), radius: 12, y: 8)
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
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.04)
                ]
                : [
                    Color.white.opacity(0.90),
                    Color.white.opacity(0.72)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(secondaryText)

            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(primaryText)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(isDarkMode ? 0.16 : 0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func actionButton(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundColor(tint)

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(primaryText)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(surfaceFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(surfaceBorder, lineWidth: 1)
        )
    }

    private func quickChip(title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(surfaceFill.opacity(isDarkMode ? 0.82 : 0.76), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(surfaceBorder, lineWidth: 1)
            )
    }
}
