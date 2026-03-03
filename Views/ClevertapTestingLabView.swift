import SwiftUI

struct ClevertapTestingLabView: View {
    @State private var selectedTest: TestType?
    @State private var testResults: [String: Any] = [:]
    @State private var isRunningTest = false
    
    enum TestType: String, CaseIterable {
        case pushNotification = "Push Notification"
        case inAppMessage = "In-App Message"
        case eventTracking = "Event Tracking"
        case userProfile = "User Profile"
        case deepLink = "Deep Link"
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Available Tests") {
                    ForEach(TestType.allCases, id: \.self) { test in
                        Button {
                            selectedTest = test
                        } label: {
                            HStack {
                                Text(test.rawValue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if !testResults.isEmpty {
                    Section("Test Results") {
                        ForEach(Array(testResults.keys.sorted()), id: \.self) { key in
                            if let value = testResults[key] {
                                VStack(alignment: .leading) {
                                    Text(key)
                                        .font(.headline)
                                    Text("\(value)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Testing Lab")
            .sheet(item: $selectedTest) { test in
                TestDetailView(test: test) { results in
                    testResults = results
                }
            }
        }
    }
}

struct TestDetailView: View {
    let test: ClevertapTestingLabView.TestType
    let onComplete: ([String: Any]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning = false
    
    var body: some View {
        NavigationView {
            VStack {
                switch test {
                case .pushNotification:
                    PushNotificationTestView()
                case .inAppMessage:
                    InAppMessageTestView()
                case .eventTracking:
                    EventTrackingTestView()
                case .userProfile:
                    UserProfileTestView()
                case .deepLink:
                    DeepLinkTestView()
                }
            }
            .navigationTitle(test.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Test Views
struct PushNotificationTestView: View {
    var body: some View {
        Text("Push Notification Test")
    }
}

struct InAppMessageTestView: View {
    var body: some View {
        Text("In-App Message Test")
    }
}

struct EventTrackingTestView: View {
    var body: some View {
        Text("Event Tracking Test")
    }
}

struct UserProfileTestView: View {
    var body: some View {
        Text("User Profile Test")
    }
}

struct DeepLinkTestView: View {
    var body: some View {
        Text("Deep Link Test")
    }
}

#Preview {
    ClevertapTestingLabView()
} 