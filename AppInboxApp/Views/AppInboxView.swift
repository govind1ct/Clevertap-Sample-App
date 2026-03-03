import SwiftUI
import CleverTapSDK

struct AppInboxView: View {
    @StateObject private var inAppService = CleverTapInAppService.shared
    @State private var selectedMessage: CleverTapInboxMessage?
    @State private var showMessageDetail = false
    @State private var refreshing = false
    @Environment(\.colorScheme) var colorScheme
    
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
                
                VStack(spacing: 0) {
                    // Header Section
                    headerSection
                    
                    // Content
                    if inAppService.appInboxMessages.isEmpty {
                        emptyStateView
                    } else {
                        messageListView
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await refreshInbox()
            }
            .sheet(isPresented: $showMessageDetail) {
                if let message = selectedMessage {
                    MessageDetailView(message: message)
                }
            }
        }
        .onAppear {
            inAppService.refreshAppInbox()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "tray.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("App Inbox")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("\(inAppService.appInboxMessages.count) messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        refreshing = true
                    }
                    inAppService.refreshAppInbox()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            refreshing = false
                        }
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .rotationEffect(.degrees(refreshing ? 360 : 0))
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Messages")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your inbox is empty")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Message List View
    private var messageListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(inAppService.appInboxMessages, id: \.id) { message in
                    MessageRow(message: message)
                        .onTapGesture {
                            selectedMessage = message
                            showMessageDetail = true
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    private func refreshInbox() async {
        inAppService.refreshAppInbox()
    }
}

struct MessageRow: View {
    let message: CleverTapInboxMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.title ?? "No Title")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !message.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(message.message ?? "No Message")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text(message.date?.formatted() ?? "")
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
}

struct MessageDetailView: View {
    let message: CleverTapInboxMessage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(message.title ?? "No Title")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(message.message ?? "No Message")
                    .font(.body)
                
                if let date = message.date {
                    Text(date.formatted())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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