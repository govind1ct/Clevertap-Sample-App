import SwiftUI

struct SplashView: View {
    
    let onFinish: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var animateIn = false
    @State private var animateOut = false
    @State private var gradientShift = false
    
    private let splashDuration: Double = 1.8
    
    var body: some View {
        ZStack {
            animatedBackground
            content
        }
        .opacity(animateOut ? 0 : 1)
        .animation(.easeInOut(duration: 0.35), value: animateOut)
        .task {
            await startSequence()
        }
    }
}

// MARK: - Background

private extension SplashView {
    
    var animatedBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.96, blue: 1.0),
                Color(red: 0.88, green: 0.94, blue: 1.0),
                Color(red: 0.95, green: 0.98, blue: 1.0)
            ],
            startPoint: gradientShift ? .topLeading : .bottomTrailing,
            endPoint: gradientShift ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .animation(
            reduceMotion ? .none : .easeInOut(duration: 4).repeatForever(autoreverses: true),
            value: gradientShift
        )
        .onAppear {
            gradientShift = true
        }
    }
}

// MARK: - Content

private extension SplashView {
    
    var content: some View {
        VStack(spacing: 0) {
            logoCard
        }
        .padding(.horizontal, 24)
    }
    
    var logoCard: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: animateIn ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.teal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .frame(width: 244, height: 244)
                .rotationEffect(.degrees(-90))
                .scaleEffect(x: -1, y: 1)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: splashDuration), value: animateIn)

            Circle()
                .fill(.white.opacity(0.55))
                .frame(width: 230, height: 230)
                .shadow(color: .white.opacity(0.55), radius: 14, x: 0, y: 0)
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)

            Image("Clevertap1")
                .resizable()
                .scaledToFill()
                .frame(width: 214, height: 214)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )
        }
        .scaleEffect(animateIn ? 1 : 0.88)
        .opacity(animateIn ? 1 : 0)
        .offset(y: floatingOffset)
        .animation(entryAnimation, value: animateIn)
    }
    
    var floatingOffset: CGFloat {
        guard animateIn, !reduceMotion else { return 0 }
        return -6
    }
}

// MARK: - Animations

private extension SplashView {
    
    var entryAnimation: Animation {
        reduceMotion
        ? .easeOut(duration: 0.25)
        : .spring(response: 0.65, dampingFraction: 0.82)
    }
}

// MARK: - Sequence

private extension SplashView {
    
    @MainActor
    func startSequence() async {
        animateIn = true
        
        let nanos = UInt64(splashDuration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
        
        animateOut = true
        
        try? await Task.sleep(nanoseconds: 350_000_000)
        onFinish()
    }
}
