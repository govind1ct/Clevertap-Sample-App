import SwiftUI

struct NativeDisplayLabView: View {
    private let nativeDisplayLocations = [
        "home_hero",
        "product_list_header",
        "cart_recommendations",
        "profile_offers",
        "product_detail_related"
    ]

    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                controlsSection

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
                                nativeDisplayService.triggerTestEvent(for: location)
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
                                .background(Color(.secondarySystemBackground).opacity(0.85), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(!nativeDisplayService.isFeatureEnabled)
                            .opacity(nativeDisplayService.isFeatureEnabled ? 1 : 0.45)
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        nativeDisplayService.refreshDisplayUnits()
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
                .disabled(!nativeDisplayService.isFeatureEnabled)
                .opacity(nativeDisplayService.isFeatureEnabled ? 1 : 0.45)

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
            .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.20), lineWidth: 1)
            )
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.10),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
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

    var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Native Display", isOn: Binding(
                get: { nativeDisplayService.isFeatureEnabled },
                set: { nativeDisplayService.setFeatureEnabled($0) }
            ))
            .toggleStyle(.switch)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !nativeDisplayService.isFeatureEnabled {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "pause.circle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Native Display Disabled")
                            .font(.subheadline.weight(.semibold))
                        Text("Display units are hidden and test triggers are ignored until you enable this again.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if nativeDisplayService.isResetStateActive {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.title3)
                        .foregroundColor(Color("CleverTapPrimary"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Native Display Reset")
                            .font(.subheadline.weight(.semibold))
                        Text("Display units are cleared locally. Use Refresh or trigger a location event to load units again.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color("CleverTapPrimary").opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    nativeDisplayService.resetDisplayUnits()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward")
                    Text("Reset Native Display")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundColor(Color("CleverTapPrimary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color("CleverTapPrimary").opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
    NavigationStack {
        NativeDisplayLabView()
    }
}
