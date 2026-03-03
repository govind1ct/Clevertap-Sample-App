import SwiftUI
import CleverTapSDK

struct CleverTapTestingLabView: View {
    @State private var selectedTest: TestType?
    @State private var showingTestDetail = false
    
    enum TestType: String, CaseIterable {
        case pushNotification = "Push Notification"
        case inAppNotification = "In-App Notification"
        case appInbox = "App Inbox"
        case profile = "Profile"
        case events = "Events"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful gradient background
                LinearGradient(
                    colors: [
                        Color("CleverTapPrimary").opacity(0.1),
                        Color("CleverTapSecondary").opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Test Types
                        testTypesSection
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingTestDetail) {
                if let test = selectedTest {
                    TestDetailView(testType: test)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Brain Icon with Glow Effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color("CleverTapPrimary").opacity(0.3),
                                Color("CleverTapSecondary").opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("CleverTap Testing Lab")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Test your in-app notifications and analytics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Test Types Section
    private var testTypesSection: some View {
        VStack(spacing: 16) {
            ForEach(TestType.allCases, id: \.self) { testType in
                TestTypeCard(testType: testType)
                    .onTapGesture {
                        selectedTest = testType
                        showingTestDetail = true
                    }
            }
        }
    }
}

struct TestTypeCard: View {
    let testType: CleverTapTestingLabView.TestType
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(testType.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var iconName: String {
        switch testType {
        case .pushNotification: return "bell.fill"
        case .inAppNotification: return "app.badge.fill"
        case .appInbox: return "tray.fill"
        case .profile: return "person.fill"
        case .events: return "chart.bar.fill"
        }
    }
    
    private var description: String {
        switch testType {
        case .pushNotification: return "Test push notification delivery"
        case .inAppNotification: return "Test in-app notification display"
        case .appInbox: return "Test app inbox functionality"
        case .profile: return "Test user profile updates"
        case .events: return "Test event tracking"
        }
    }
}

struct TestDetailView: View {
    let testType: CleverTapTestingLabView.TestType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Test specific content will be added here
                    Text("Test: \(testType.rawValue)")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding()
            }
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