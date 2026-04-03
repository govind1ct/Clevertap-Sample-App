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

    private var shellFill: Color {
        isDarkMode ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color.white.opacity(0.94)
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
        isDarkMode ? Color(red: 0.93, green: 0.68, blue: 0.34) : Color(red: 0.63, green: 0.41, blue: 0.12)
    }

    private var accentSoft: Color {
        accent.opacity(isDarkMode ? 0.18 : 0.10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ADMIN DESK")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(secondaryText)

                    Text("Commerce Command")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)

                    Text("Run catalog, banners, orders, and bulk operations from one focused mobile console.")
                        .font(.footnote)
                        .foregroundStyle(secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accentSoft)
                        .frame(width: 64, height: 64)

                    Image(systemName: "slider.horizontal.3")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(accent)
                }
            }

            HStack(spacing: 10) {
                statStrip(title: "Catalog", value: "\(productCount)", subtitle: "items")
                statStrip(title: "Orders", value: "\(orderCount)", subtitle: "total")
                statStrip(title: "Queue", value: "\(processingOrderCount)", subtitle: "processing")
            }

            HStack(spacing: 10) {
                metaPill(title: "\(visibleCount) visible")
                metaPill(title: "\(lowStockCount) low stock")
                if selectedCount > 0 || isSelectionMode {
                    metaPill(title: isSelectionMode ? "\(selectedCount) selected" : "Bulk off")
                }
            }

            VStack(spacing: 10) {
                Button(action: onAdd) {
                    primaryAction(title: "Add Product", systemImage: "plus")
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button(action: onToggleSelection) {
                        secondaryAction(
                            title: isSelectionMode ? "Leave Bulk" : "Bulk Edit",
                            systemImage: isSelectionMode ? "checkmark.circle.fill" : "checklist",
                            tint: isSelectionMode ? .green : accent
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AdminOrdersView()
                    } label: {
                        secondaryAction(title: "Orders", systemImage: "shippingbox.fill", tint: .blue)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    AdminAuditLogView()
                } label: {
                    tertiaryAction(title: "Audit Trail", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(shellFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDarkMode ? 0.18 : 0.06), radius: 16, y: 10)
    }

    private func statStrip(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(secondaryText)

            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(primaryText)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
    }

    private func metaPill(title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isDarkMode ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
            .overlay(
                Capsule()
                    .stroke(shellBorder, lineWidth: 1)
            )
    }

    private func primaryAction(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.subheadline.weight(.bold))
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(isDarkMode ? Color.black.opacity(0.88) : .white)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accent)
        )
    }

    private func secondaryAction(title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(primaryText)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
    }

    private func tertiaryAction(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(secondaryText)
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(primaryText)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.04) : Color.black.opacity(0.025))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(shellBorder, lineWidth: 1)
        )
    }
}
