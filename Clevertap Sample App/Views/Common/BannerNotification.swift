import SwiftUI

struct BannerNotification: View {
    let title: String
    let message: String
    let type: BannerType
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding()
                .background(BlurView(style: .systemMaterial))
                .cornerRadius(16)
                .shadow(radius: 8)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { isVisible = false }
            }
            .zIndex(1)
            .animation(.spring(), value: isVisible)
        }
    }
}

enum BannerType {
    case success, error, info
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 