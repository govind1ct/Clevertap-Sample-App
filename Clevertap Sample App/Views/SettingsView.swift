import SwiftUI

struct SettingsView: View {
    @AppStorage("hasSeenMainTabWalkthrough") private var hasSeenMainTabWalkthrough: Bool = false
    @StateObject private var productExperiencesService = CleverTapProductExperiencesService.shared
    @State private var showReplayConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section("General") {
                    Text("Manage demo and guidance preferences.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Toggle("Enable Product Experiences", isOn: Binding(
                        get: { productExperiencesService.isFeatureEnabled },
                        set: { productExperiencesService.setFeatureEnabled($0) }
                    ))

                    Text(productExperiencesService.isFeatureEnabled
                         ? "Remote variables can be fetched and applied."
                         : "Product Experiences are disabled and app defaults are used.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Guided Walkthrough") {
                    Button {
                        hasSeenMainTabWalkthrough = false
                        NotificationCenter.default.post(name: .replayMainTabWalkthrough, object: nil)
                        showReplayConfirmation = true
                    } label: {
                        Label("Replay App Walkthrough", systemImage: "arrow.counterclockwise.circle")
                    }

                    Text("Shows first-time tab nudges again for Home, Experiences, Cart, and Profile.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Walkthrough reset. Open main tabs to view nudges again.", isPresented: $showReplayConfirmation) {
                Button("OK", role: .cancel) { }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
