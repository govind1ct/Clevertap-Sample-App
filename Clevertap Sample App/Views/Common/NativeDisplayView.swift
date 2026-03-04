import SwiftUI
import CleverTapSDK

struct NativeDisplayView: View {
    let displayUnit: CleverTapDisplayUnit
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            if let contents = displayUnit.contents, !contents.isEmpty {
                ForEach(Array(contents.enumerated()), id: \.offset) { index, content in
                    NativeDisplayContentView(
                        content: content,
                        displayUnit: displayUnit,
                        backgroundColor: displayUnit.bgColor != nil ? UIColor(hex: displayUnit.bgColor!) : nil
                    )
                }
            } else {
                EmptyView()
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                nativeDisplayService.trackDisplayUnitViewed(displayUnit)
            }
        }
    }
}

struct NativeDisplayContentView: View {
    let content: CleverTapDisplayUnitContent
    let displayUnit: CleverTapDisplayUnit
    let backgroundColor: UIColor?
    @StateObject private var nativeDisplayService = CleverTapNativeDisplayService.shared

    private var resolvedMediaURL: String? {
        if let mediaUrl = content.mediaUrl, !mediaUrl.isEmpty {
            return mediaUrl
        }

        if let reflected = reflectedURLCandidate(from: content) {
            return reflected
        }

        guard let extras = displayUnit.customExtras else { return nil }
        let keys = ["image", "image_url", "img", "media_url", "banner", "hero_image"]
        for key in keys {
            if let value = extras[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func reflectedURLCandidate(from content: CleverTapDisplayUnitContent) -> String? {
        // Robust fallback for SDK payload variations where image URL may be exposed
        // through different properties (poster/icon/image/etc.) not covered by mediaUrl.
        let interesting = ["media", "image", "img", "poster", "icon", "url"]
        for child in Mirror(reflecting: content).children {
            guard let label = child.label?.lowercased() else { continue }
            guard interesting.contains(where: { label.contains($0) }) else { continue }

            if let value = child.value as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }
    
    var body: some View {
        Button(action: {
            nativeDisplayService.trackDisplayUnitClicked(displayUnit, content: content)
            
            // Handle action URL
            if let actionUrl = content.actionUrl, let url = URL(string: actionUrl) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                if let title = content.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Message
                if let message = content.message, !message.isEmpty {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Media Content
                mediaContentView
                
                // Action Button
                if let actionUrl = content.actionUrl, !actionUrl.isEmpty {
                    HStack {
                        Spacer()
                        Text("Learn More")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 20)
                            )
                    }
                }
            }
            .padding(16)
            .background(
                backgroundColor != nil ? Color(backgroundColor!) : Color(.systemBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var mediaContentView: some View {
        if let mediaUrl = resolvedMediaURL, !mediaUrl.isEmpty {
            // Some campaigns may provide a media URL but not set media-type flags correctly.
            // Treat unknown media type as image by default for resilient rendering.
            if content.mediaIsImage || (!content.mediaIsVideo && !content.mediaIsAudio) {
                // For image content
                AppAsyncImage(urlString: mediaUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
                
            } else if content.mediaIsVideo {
                // For video content, show poster image with play button
                ZStack {
                    AppAsyncImage(urlString: content.videoPosterUrl ?? content.mediaUrl) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    
                    // Play button overlay
                    Button(action: {
                        if let mediaUrl = content.mediaUrl, let url = URL(string: mediaUrl) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.6))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                
            } else if content.mediaIsAudio {
                // For audio content, show a simple audio player interface
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Audio Content")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Tap to play")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let mediaUrl = content.mediaUrl, let url = URL(string: mediaUrl) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
            }
        }
    }
}

// Helper extension for UIColor from hex string
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// Helper extension for Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct NativeDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        // This is just for preview purposes
        VStack {
            Text("Native Display Preview")
                .padding()
        }
    }
} 
