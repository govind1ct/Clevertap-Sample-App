import SwiftUI

struct ProductExperiencesView: View {
    private enum ExperienceSection {
        case productExperiences
        case testLab
    }

    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedSection: ExperienceSection = .productExperiences

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                sectionSelector

                if selectedSection == .productExperiences {
                    variableStatusSection
                    actionsSection
                    guideSection
                } else {
                    testLabSection
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Product Experiences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            productExperiencesService.fetchVariables()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") { }
        }
    }
}

private extension ProductExperiencesView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CleverTap Remote Config")
                .font(.title2)
                .fontWeight(.bold)
            Text("Control Home screen content from Product Experiences without shipping a new app build.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var sectionSelector: some View {
        HStack(spacing: 12) {
            selectorCard(
                title: "Product Experiences",
                subtitle: "Remote config variables",
                icon: "shippingbox.fill",
                isSelected: selectedSection == .productExperiences
            ) {
                selectedSection = .productExperiences
            }

            selectorCard(
                title: "CleverTap Test Lab",
                subtitle: "Push, in-app, inbox tests",
                icon: "brain.head.profile",
                isSelected: selectedSection == .testLab
            ) {
                selectedSection = .testLab
            }
        }
    }

    var variableStatusSection: some View {
        VStack(spacing: 12) {
            statusRow(title: "Fetch Status", value: productExperiencesService.hasFetchedVariables ? "Fetched" : "Not fetched")
            statusRow(title: "home_header_title", value: productExperiencesService.homeHeaderTitle)
            statusRow(title: "home_header_subtitle", value: productExperiencesService.homeHeaderSubtitle)
            statusRow(title: "home_featured_section_title", value: productExperiencesService.featuredSectionTitle)
            statusRow(title: "home_show_featured_section", value: productExperiencesService.showFeaturedSection ? "true" : "false")
            statusRow(title: "home_max_featured_products", value: "\(productExperiencesService.maxFeaturedProducts)")
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    var actionsSection: some View {
        HStack(spacing: 12) {
            Button {
                productExperiencesService.fetchVariables { success in
                    alertMessage = success ? "Variables fetched successfully." : "Failed to fetch variables."
                    showAlert = true
                }
            } label: {
                actionLabel(title: "Fetch", icon: "arrow.clockwise")
            }

            Button {
                productExperiencesService.syncVariablesInDebugBuild()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    productExperiencesService.fetchVariables { success in
                        alertMessage = success ? "Sync + fetch completed." : "Sync triggered, fetch failed."
                        showAlert = true
                    }
                }
            } label: {
                actionLabel(title: "Sync (Debug)", icon: "hammer")
            }
        }
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
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            .padding(14)
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
            .opacity(isSelected ? 1.0 : 0.9)
        }
        .buttonStyle(.plain)
    }

    func statusRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
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
}

#Preview {
    NavigationStack {
        ProductExperiencesView()
    }
}
