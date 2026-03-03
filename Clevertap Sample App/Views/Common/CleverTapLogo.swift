import SwiftUI

struct CleverTapLogo: View {
    var size: CGFloat = 60
    var showText: Bool = true
    var textSize: CGFloat = 36
    var animate: Bool = false
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            Image("CleverTap logo")
                .resizable()
                .scaledToFit()
                .frame(width: size * 2.5) // Adjusting for the aspect ratio of the logo
                .opacity(animate ? (isAnimating ? 1 : 0) : 1)
                .scaleEffect(animate ? (isAnimating ? 1 : 0.5) : 1)
        }
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
} 