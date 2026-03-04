import SwiftUI

struct NativeDisplayLabView: View {
    private let nativeDisplayLocations = [
        "home_hero",
        "product_list_header",
        "cart_recommendations",
        "profile_offers",
        "product_detail_related"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(
                title: "Native Display",
                subtitle: "Test dynamic content locations and campaign payload"
            )

            NativeDisplayStatusCard()
            NativeDisplayImplementationCard()

            VStack(spacing: 8) {
                ForEach(nativeDisplayLocations, id: \.self) { location in
                    TestActionCard(
                        title: "Test \(location.capitalized)",
                        subtitle: "Trigger event for this location",
                        icon: "rectangle.badge.plus",
                        gradient: [Color.purple, Color.blue],
                        action: {
                            CleverTapNativeDisplayService.shared.triggerTestEvent(for: location)
                        }
                    )
                }
            }

            TestActionCard(
                title: "Refresh Units",
                subtitle: "Pull latest display units",
                icon: "arrow.clockwise",
                gradient: [Color.blue, Color.cyan],
                action: {
                    CleverTapNativeDisplayService.shared.refreshDisplayUnits()
                }
            )

            NavigationLink(destination: NativeDisplayDebugView()) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.green)
                    Text("View All Display Units")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    ScrollView {
        NativeDisplayLabView()
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
