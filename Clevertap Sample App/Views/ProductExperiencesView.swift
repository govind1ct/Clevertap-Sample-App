import SwiftUI

struct ProductExperiencesView: View {
    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                variableStatusSection
                actionsSection
                guideSection
                testLabLinkSection
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

    var testLabLinkSection: some View {
        NavigationLink {
            CleverTapTestView()
        } label: {
            HStack {
                Image(systemName: "testtube.2")
                Text("Open Test Lab")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
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
