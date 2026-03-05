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
        VStack(alignment: .leading, spacing: 18) {
            headerCard

            NativeDisplayStatusCard()
            NativeDisplayImplementationCard()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Location Triggers")
                        .font(.headline)
                    Spacer()
                    Text("Instant event fire")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(nativeDisplayLocations, id: \.self) { location in
                        Button {
                            CleverTapNativeDisplayService.shared.triggerTestEvent(for: location)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: "rectangle.badge.plus")
                                        .font(.caption.weight(.semibold))
                                    Text("Trigger")
                                        .font(.caption2.weight(.semibold))
                                }
                                .foregroundColor(Color("CleverTapPrimary"))

                                Text(formatLocationLabel(location))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(.secondarySystemBackground).opacity(0.78), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            )

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    CleverTapNativeDisplayService.shared.refreshDisplayUnits()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Display Units")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Live")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2), in: Capsule())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: NativeDisplayDebugView()) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.green)
                    Text("View All Display Units")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(14)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.green.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NATIVE DISPLAY CONTROL")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color("CleverTapPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())

            Text("Native Display")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)

            Text("Trigger location-specific events, refresh units, and inspect payload rendering with production-safe controls.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
    }

    func formatLocationLabel(_ location: String) -> String {
        location
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

#Preview {
    ScrollView {
        NativeDisplayLabView()
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}
