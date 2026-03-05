import SwiftUI

struct ProductExperiencesView: View {
    private enum ExperienceSection {
        case productExperiences
        case testLab
        case nativeDisplay
    }

    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedSection: ExperienceSection = .productExperiences
    @State private var animateContent = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("CleverTapPrimary").opacity(0.20),
                    Color("CleverTapSecondary").opacity(0.10),
                    Color(.systemBackground),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color("CleverTapPrimary").opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 36)
                .offset(x: -150, y: -360)

            Circle()
                .fill(Color("CleverTapSecondary").opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 44)
                .offset(x: 170, y: -280)

            ScrollView {
                VStack(spacing: 22) {
                    headerSection

                    if !CleverTapProductExperiencesService.isFeatureEnabled {
                        disabledBanner
                    }

                    sectionSelector

                    if selectedSection == .productExperiences {
                        variableStatusSection
                        actionsSection
                        demoPresetsSection
                        guideSection
                    } else if selectedSection == .testLab {
                        testLabSection
                    } else {
                        nativeDisplaySection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 44)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 12)
                .animation(.spring(response: 0.46, dampingFraction: 0.86), value: animateContent)
            }
        }
        .navigationTitle("Experiences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !animateContent {
                animateContent = true
            }
            if !productExperiencesService.isDemoModeLocked {
                productExperiencesService.fetchVariables()
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") { }
        }
    }
}

private extension ProductExperiencesView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("REMOTE EXPERIENCE STUDIO")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("CleverTapPrimary").opacity(0.14), in: Capsule())

                    Text("Experiences")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Control Home UI in real time with polished demo controls and production-safe fetch flows.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 16)

                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 52, height: 52)
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color("CleverTapPrimary"))
                }
            }

            HStack(spacing: 10) {
                quickBadge(
                    title: "Mode",
                    value: productExperiencesService.isDemoModeLocked ? "Demo Locked" : "Live Fetch"
                )
                quickBadge(
                    title: "Status",
                    value: productExperiencesService.hasFetchedVariables ? "Fetched" : "Idle"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    var sectionSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                selectorCard(
                    title: "Product Experiences",
                    subtitle: "Remote config variables",
                    icon: "shippingbox.fill",
                    isSelected: selectedSection == .productExperiences
                ) {
                    selectedSection = .productExperiences
                }
                .frame(width: 210)

                selectorCard(
                    title: "CleverTap Test Lab",
                    subtitle: "Push, in-app, inbox tests",
                    icon: "brain.head.profile",
                    isSelected: selectedSection == .testLab
                ) {
                    selectedSection = .testLab
                }
                .frame(width: 210)

                selectorCard(
                    title: "Native Display",
                    subtitle: "Display units and locations",
                    icon: "rectangle.3.group.fill",
                    isSelected: selectedSection == .nativeDisplay
                ) {
                    selectedSection = .nativeDisplay
                }
                .frame(width: 210)
            }
        }
    }

    var variableStatusSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Live Variable Snapshot")
                    .font(.headline)
                Spacer()
                Text(productExperiencesService.hasFetchedVariables ? "Synced" : "Not Synced")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(productExperiencesService.hasFetchedVariables ? .green : .orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((productExperiencesService.hasFetchedVariables ? Color.green : Color.orange).opacity(0.13), in: Capsule())
            }

            VStack(spacing: 10) {
                statusRow(title: "home_header_title", value: productExperiencesService.homeHeaderTitle)
                statusRow(title: "home_header_subtitle", value: productExperiencesService.homeHeaderSubtitle)
                statusRow(title: "home_featured_section_title", value: productExperiencesService.featuredSectionTitle)
                statusRow(title: "home_show_featured_section", value: productExperiencesService.showFeaturedSection ? "true" : "false")
                statusRow(title: "home_max_featured_products", value: "\(productExperiencesService.maxFeaturedProducts)")
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var actionsSection: some View {
        HStack(spacing: 12) {
            Button {
                guard !productExperiencesService.isDemoModeLocked else {
                    alertMessage = "Demo Mode Lock is ON. Disable it to fetch dashboard values."
                    showAlert = true
                    return
                }
                productExperiencesService.fetchVariables { success in
                    alertMessage = success ? "Variables fetched successfully." : "Failed to fetch variables."
                    showAlert = true
                }
            } label: {
                prominentActionLabel(title: "Fetch", icon: "arrow.clockwise", gradient: [Color("CleverTapPrimary"), Color("CleverTapSecondary")])
            }
            .disabled(!CleverTapProductExperiencesService.isFeatureEnabled)

            Button {
                guard !productExperiencesService.isDemoModeLocked else {
                    alertMessage = "Demo Mode Lock is ON. Disable it to sync/fetch dashboard values."
                    showAlert = true
                    return
                }
                productExperiencesService.syncVariablesInDebugBuild()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    productExperiencesService.fetchVariables { success in
                        alertMessage = success ? "Sync + fetch completed." : "Sync triggered, fetch failed."
                        showAlert = true
                    }
                }
            } label: {
                prominentActionLabel(title: "Sync (Debug)", icon: "hammer", gradient: [Color.indigo, Color.blue])
            }
            .disabled(!CleverTapProductExperiencesService.isFeatureEnabled)
        }
    }

    var demoPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Demo Presets")
                    .font(.headline)
                Spacer()
                Text("Local preview")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Use these for quick client walkthroughs. For actual CleverTap demo, publish values in dashboard and tap Fetch.")
                .font(.caption)
                .foregroundColor(.secondary)

            Toggle(isOn: Binding(
                get: { productExperiencesService.isDemoModeLocked },
                set: { productExperiencesService.setDemoModeLocked($0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Demo Mode Lock")
                        .font(.subheadline.weight(.semibold))
                    Text(productExperiencesService.isDemoModeLocked
                         ? "Presets stay fixed. Remote fetch is paused."
                         : "Remote values can update this screen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Button {
                    productExperiencesService.applyDemoPreset(.luxuryLaunch)
                    alertMessage = "Applied preset: Luxury Launch."
                    showAlert = true
                } label: {
                    actionLabel(title: "Luxury", icon: "sparkles")
                }
                .disabled(!CleverTapProductExperiencesService.isFeatureEnabled)

                Button {
                    productExperiencesService.applyDemoPreset(.festiveSale)
                    alertMessage = "Applied preset: Festive Sale."
                    showAlert = true
                } label: {
                    actionLabel(title: "Festive", icon: "tag.fill")
                }
                .disabled(!CleverTapProductExperiencesService.isFeatureEnabled)

                Button {
                    productExperiencesService.applyDemoPreset(.reset)
                    alertMessage = "Reset to app defaults."
                    showAlert = true
                } label: {
                    actionLabel(title: "Reset", icon: "arrow.uturn.backward")
                }
                .disabled(!CleverTapProductExperiencesService.isFeatureEnabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var disabledBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "pause.circle.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Product Experiences Disabled")
                    .font(.subheadline.weight(.semibold))
                Text("Home uses app defaults only. Remote dashboard values are ignored.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.orange.opacity(0.25), lineWidth: 1)
        )
    }

    var guideSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How To Use")
                .font(.headline)

            Text("1. Update variable values in CleverTap Product Experiences.")
            Text("2. In app, open this tab and tap `Fetch` (or `Sync (Debug)` in debug builds).")
            Text("3. Go to Home tab and verify the updated header, featured title, visibility, and item count.")
            Text("4. If updates depend on user profile/segment, re-login or update profile, then fetch again.")
            Text("5. Keep variable names exactly as shown in the status list above.")
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var testLabSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CleverTap Test Lab")
                .font(.headline)

            Text("Use the Test Lab to validate push, in-app templates, app inbox, and native display behavior.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            NavigationLink {
                CleverTapTestView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open CleverTap Test Lab")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Run full test workflows")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.92))
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .shadow(color: Color("CleverTapPrimary").opacity(0.32), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    var nativeDisplaySection: some View {
        NativeDisplayLabView()
    }

    func selectorCard(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            (isSelected ? Color.white.opacity(0.18) : Color.secondary.opacity(0.12)),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    Spacer()
                    if isSelected {
                        Label("Selected", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                    }
                }

                Text(title)
                    .font(.headline)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                    .lineLimit(2)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color("CleverTapPrimary").opacity(0.22) : .clear, radius: 8, y: 5)
            .opacity(isSelected ? 1.0 : 0.92)
        }
        .buttonStyle(.plain)
    }

    func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    func actionLabel(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    func prominentActionLabel(title: String, icon: String, gradient: [Color]) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(
            LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: gradient.first?.opacity(0.32) ?? .clear, radius: 10, y: 7)
    }

    func quickBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ProductExperiencesView()
    }
}
