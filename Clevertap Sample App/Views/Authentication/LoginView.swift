import SwiftUI

struct AuthLoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var isGoogleLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuthBackgroundView()

                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 22) {
                            AuthBrandHeader(
                                title: "Welcome Back",
                                subtitle: "Sign in to continue with CleverTap demo flows",
                                logoStyle: .circular
                            )
                            formCard
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .frame(minHeight: proxy.size.height, alignment: .center)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView()
                    .environmentObject(viewModel)
            }
            .onReceive(viewModel.$isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    isLoading = false
                    isGoogleLoading = false
                }
            }
            .onReceive(viewModel.$errorMessage) { error in
                if error != nil {
                    isLoading = false
                    isGoogleLoading = false
                }
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 16) {
            AuthTextFieldRow(
                text: $email,
                placeholder: "Email",
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                isSecure: false,
                trailingView: nil
            )

            AuthTextFieldRow(
                text: $password,
                placeholder: "Password",
                icon: "lock.fill",
                keyboardType: .default,
                isSecure: !isPasswordVisible,
                trailingView: AnyView(passwordToggle)
            )

            Group {
                if let error = viewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Color.clear
                        .frame(height: 16)
                }
            }

            Button {
                signInWithEmail()
            } label: {
                ZStack {
                    HStack(spacing: 8) {
                        Text("Sign In")
                        Image(systemName: "arrow.right")
                    }
                    .opacity(isLoading ? 0 : 1)

                    ProgressView()
                        .tint(.white)
                        .opacity(isLoading ? 1 : 0)
                }
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color("CleverTapPrimary"), Color("CleverTapSecondary")],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading || isGoogleLoading)
            .opacity(email.isEmpty || password.isEmpty ? 0.65 : 1)

            HStack {
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
                Text("OR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
            }

            Button {
                signInWithGoogle()
            } label: {
                HStack(spacing: 12) {
                    if isGoogleLoading {
                        ProgressView()
                            .tint(.primary)
                            .frame(width: 30, height: 30)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 30, height: 30)
                                .overlay(Circle().stroke(Color.black.opacity(0.10), lineWidth: 1))
                            Text("G")
                                .font(.caption.weight(.black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.26, green: 0.52, blue: 0.96),
                                            Color(red: 0.30, green: 0.74, blue: 0.35),
                                            Color(red: 0.98, green: 0.78, blue: 0.22),
                                            Color(red: 0.95, green: 0.33, blue: 0.29)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Continue with Google")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                        Text("Fast and secure sign in")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
            }
            .buttonStyle(PremiumGoogleButtonStyle(colorScheme: colorScheme))
            .disabled(isLoading || isGoogleLoading)

            Button {
                isShowingSignUp = true
            } label: {
                HStack(spacing: 5) {
                    Text("New here?")
                        .foregroundStyle(.secondary)
                    Text("Create account")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("CleverTapPrimary"))
                }
                .font(.footnote)
            }
            .padding(.top, 2)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.40), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
        .animation(.none, value: isLoading)
        .animation(.none, value: isGoogleLoading)
        .animation(.none, value: viewModel.errorMessage)
    }

    private var passwordToggle: some View {
        Button {
            isPasswordVisible.toggle()
        } label: {
            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                .foregroundStyle(.secondary)
        }
    }

    private func signInWithEmail() {
        viewModel.errorMessage = nil
        isLoading = true
        viewModel.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
    }

    private func signInWithGoogle() {
        viewModel.errorMessage = nil
        isGoogleLoading = true
        viewModel.signInWithGoogle(source: "login")
    }
}

struct AuthBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                ? [Color(red: 0.03, green: 0.05, blue: 0.10), Color(red: 0.06, green: 0.09, blue: 0.16)]
                : [Color(red: 0.95, green: 0.97, blue: 1.0), Color(red: 0.91, green: 0.95, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color("CleverTapPrimary").opacity(colorScheme == .dark ? 0.30 : 0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 54)
                .offset(x: -90, y: -120)
            Circle()
                .fill(Color("CleverTapSecondary").opacity(colorScheme == .dark ? 0.24 : 0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 64)
                .offset(x: 140, y: 240)
        }
        .ignoresSafeArea()
    }
}

private struct PremiumGoogleButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color.white.opacity(0.10), Color.white.opacity(0.05)]
                        : [Color.white, Color(red: 0.97, green: 0.98, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.08), radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AuthBrandHeader: View {
    enum LogoStyle {
        case standard
        case circular
    }

    let title: String
    let subtitle: String
    var highlights: [String] = ["Realtime Personalization", "Native Display", "Journey Analytics"]
    var logoStyle: LogoStyle = .standard

    var body: some View {
        VStack(spacing: 12) {
            Group {
                switch logoStyle {
                case .standard:
                    Image("CleverTap logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180)
                        .padding(.vertical, 10)

                case .circular:
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.92))

                        Image("CleverTap logo")
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                    }
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
                    .padding(.vertical, 6)
                }
            }

            Text(title)
                .font(.system(size: 33, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(highlights, id: \.self) { item in
                        Text(item)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("CleverTapPrimary"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color("CleverTapPrimary").opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }
}

struct AuthTextFieldRow: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let trailingView: AnyView?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color("CleverTapPrimary"))
                .frame(width: 22)

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if let trailingView {
                trailingView
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
