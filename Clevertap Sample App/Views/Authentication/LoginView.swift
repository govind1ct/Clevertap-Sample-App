import SwiftUI

struct AuthLoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel

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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        Spacer(minLength: 22)
                        AuthBrandHeader(title: "Welcome Back", subtitle: "Sign in to continue with CleverTap demo flows")
                        formCard
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
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

            if let error = viewModel.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                signInWithEmail()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Sign In")
                        Image(systemName: "arrow.right")
                    }
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
                HStack(spacing: 10) {
                    if isGoogleLoading {
                        ProgressView().tint(.primary)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
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
                    Text("Continue with Google")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Color.white,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
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
                .stroke(Color.white.opacity(0.40), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: 10)
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

struct AuthBrandHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image("CleverTap logo")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .padding(.vertical, 10)

            Text(title)
                .font(.system(size: 33, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
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
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }
}
