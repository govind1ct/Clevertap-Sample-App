import SwiftUI

struct AdminOrdersView: View {
    @StateObject private var orderService = AdminOrderService()
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var selectedStatus = "All"

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var statusOptions: [String] {
        ["All", "Placed", "Processing", "Shipped", "Delivered", "Cancelled"]
    }

    private var filteredOrders: [Order] {
        orderService.orders.filter { order in
            let matchesStatus = selectedStatus == "All" || order.status.caseInsensitiveCompare(selectedStatus) == .orderedSame
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesSearch = query.isEmpty ||
                (order.id?.lowercased().contains(query) ?? false) ||
                order.userId.lowercased().contains(query) ||
                (order.userEmail?.lowercased().contains(query) ?? false)

            return matchesStatus && matchesSearch
        }
    }

    private var processingCount: Int {
        orderService.orders.filter { $0.status.caseInsensitiveCompare("Processing") == .orderedSame }.count
    }

    private var deliveredCount: Int {
        orderService.orders.filter { $0.status.caseInsensitiveCompare("Delivered") == .orderedSame }.count
    }

    private var placedCount: Int {
        orderService.orders.filter { $0.status.caseInsensitiveCompare("Placed") == .orderedSame }.count
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color(.systemBackground), Color(red: 0.08, green: 0.10, blue: 0.14), Color(.systemGroupedBackground)]
                    : [Color("CleverTapPrimary").opacity(0.12), Color("CleverTapSecondary").opacity(0.08), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerCard
                    controlBar
                    statsStrip

                    if orderService.isLoading {
                        stateCard(
                            icon: "shippingbox.circle.fill",
                            title: "Loading orders",
                            message: "Fetching the latest order stream from Firestore."
                        ) {
                            ProgressView()
                                .tint(Color("CleverTapPrimary"))
                        }
                    } else if let errorMessage = orderService.errorMessage {
                        stateCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Unable to load orders",
                            message: errorMessage
                        ) {
                            Button("Retry") {
                                Task {
                                    await orderService.fetchOrders()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else if filteredOrders.isEmpty {
                        stateCard(
                            icon: "tray.fill",
                            title: "No orders found",
                            message: searchText.isEmpty && selectedStatus == "All"
                                ? "Orders will appear here once customers place them."
                                : "Adjust the current search or status filter to widen the result set."
                        ) {
                            EmptyView()
                        }
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredOrders) { order in
                                AdminOrderCard(
                                    order: order,
                                    statusOptions: statusOptions.filter { $0 != "All" },
                                    onUpdateStatus: { status in
                                        Task {
                                            await orderService.updateOrderStatus(order: order, status: status)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard orderService.orders.isEmpty else { return }
            await orderService.fetchOrders()
        }
        .refreshable {
            await orderService.fetchOrders()
        }
    }
}

private extension AdminOrdersView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Orders")
                        .font(.title2.weight(.black))
                        .foregroundColor(isDarkMode ? .white : .primary)

                    Text("Track, filter, and update fulfillment from one place.")
                        .font(.caption)
                        .foregroundColor(isDarkMode ? .white.opacity(0.68) : .secondary)
                }

                Spacer(minLength: 0)

                Text("\(filteredOrders.count) shown")
                    .font(.caption.weight(.bold))
                    .foregroundColor(isDarkMode ? .white.opacity(0.78) : Color("CleverTapPrimary"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(isDarkMode ? 0.16 : 0.05), in: Capsule())
            }

            HStack(spacing: 10) {
                heroBadge(title: "Orders", value: "\(orderService.orders.count)")
                heroBadge(title: "Processing", value: "\(processingCount)")
                heroBadge(title: "Delivered", value: "\(deliveredCount)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDarkMode
                    ? [Color.white.opacity(0.06), Color.white.opacity(0.04)]
                    : [Color.white.opacity(0.72), Color.white.opacity(0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.56), lineWidth: 1)
        )
    }

    var controlBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search by order ID, user ID, or email", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(isDarkMode ? 0.14 : 0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(statusOptions, id: \.self) { status in
                        Button(status) {
                            selectedStatus = status
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(selectedStatus == status ? .white : Color("CleverTapPrimary"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedStatus == status ? Color("CleverTapPrimary") : Color("CleverTapPrimary").opacity(0.12),
                            in: Capsule()
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDarkMode ? Color.white.opacity(0.04) : Color.white.opacity(0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isDarkMode ? Color.white.opacity(0.08) : Color.white.opacity(0.55), lineWidth: 1)
        )
    }

    var statsStrip: some View {
        HStack(spacing: 12) {
            orderStatCard(title: "Placed", value: "\(placedCount)", tint: Color("CleverTapPrimary"))
            orderStatCard(title: "Processing", value: "\(processingCount)", tint: .orange)
            orderStatCard(title: "Delivered", value: "\(deliveredCount)", tint: .green)
        }
    }

    func heroBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundColor(isDarkMode ? .white.opacity(0.64) : .secondary)
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundColor(isDarkMode ? .white : .primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(isDarkMode ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func orderStatCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(isDarkMode ? .white.opacity(0.68) : .secondary)
            Text(value)
                .font(.headline.weight(.black))
                .foregroundColor(isDarkMode ? .white : .primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(isDarkMode ? 0.18 : 0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func stateCard<Accessory: View>(icon: String, title: String, message: String, @ViewBuilder accessory: () -> Accessory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title.weight(.bold))
                .foregroundColor(Color("CleverTapPrimary"))

            Text(title)
                .font(.headline.weight(.bold))

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            accessory()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct AdminOrderCard: View {
    let order: Order
    let statusOptions: [String]
    let onUpdateStatus: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.id ?? "Unknown Order")
                        .font(.headline.weight(.bold))
                    Text(order.userEmail ?? order.userId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(order.status)
                    .font(.caption.weight(.bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 10) {
                metricCard(title: "Total", value: "₹\(Int(order.total))", tint: Color("CleverTapPrimary"))
                metricCard(title: "Items", value: "\(order.items.count)", tint: .orange)
                metricCard(title: "Placed", value: order.createdAt.formatted(date: .abbreviated, time: .omitted), tint: .blue)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Delivery")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)

                Text(order.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Menu {
                ForEach(statusOptions, id: \.self) { status in
                    Button(status) {
                        onUpdateStatus(status)
                    }
                }
            } label: {
                HStack {
                    Text("Update Status")
                        .font(.caption.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color("CleverTapPrimary").opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch order.status.lowercased() {
        case "delivered":
            return .green
        case "cancelled":
            return .red
        case "shipped":
            return .blue
        case "processing":
            return .orange
        default:
            return Color("CleverTapPrimary")
        }
    }

    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
