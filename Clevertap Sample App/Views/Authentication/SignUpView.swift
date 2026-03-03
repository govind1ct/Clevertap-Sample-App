import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
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
                        AuthBrandHeader(title: "Create Account", subtitle: "Set up your profile to test CleverTap user journeys")
                        signUpCard
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .onReceive(viewModel.$isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    isLoading = false
                    isGoogleLoading = false
                    dismiss()
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

    private var signUpCard: some View {
        VStack(spacing: 16) {
            AuthTextFieldRow(
                text: $name,
                placeholder: "Full Name",
                icon: "person.fill",
                keyboardType: .default,
                isSecure: false,
                trailingView: nil
            )

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

            AuthTextFieldRow(
                text: $confirmPassword,
                placeholder: "Confirm Password",
                icon: "checkmark.shield.fill",
                keyboardType: .default,
                isSecure: !isPasswordVisible,
                trailingView: nil
            )

            if let error = viewModel.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                createAccount()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Account")
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
            .disabled(!isFormValid || isLoading || isGoogleLoading)
            .opacity(isFormValid ? 1 : 0.65)

            HStack {
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
                Text("OR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                Rectangle().fill(Color.primary.opacity(0.12)).frame(height: 1)
            }

            Button {
                signUpWithGoogle()
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
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)
                    Text("Sign In")
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

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty
    }

    private func createAccount() {
        guard password == confirmPassword else {
            viewModel.errorMessage = "Passwords do not match"
            return
        }

        viewModel.errorMessage = nil
        isLoading = true
        viewModel.signUp(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func signUpWithGoogle() {
        viewModel.errorMessage = nil
        isGoogleLoading = true
        viewModel.signInWithGoogle(source: "signup")
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
