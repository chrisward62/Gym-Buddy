import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {

                    // Header
                    VStack(spacing: 8) {
                        Text("🏋️")
                            .font(.system(size: 60))
                        Text("Join Dumbelle")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Find your perfect gym partner")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                    .padding(.top, 60)

                    // Fields
                    VStack(spacing: 16) {
                        DumbelleTextField(placeholder: "Email", text: $email, isSecure: false)
                        DumbelleTextField(placeholder: "Password", text: $password, isSecure: true)
                        DumbelleTextField(placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                    }

                    // Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.dumbelleDestructive)
                    }

                    // Sign Up Button
                    DumbelleButton(title: "Create Account", variant: .primary, isLoading: isLoading) {
                        handleSignUp()
                    }

                    // Back to Login
                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? ")
                            .foregroundColor(.dumbelleTextSecondary)
                        + Text("Log In")
                            .foregroundColor(.dumbelleAccent)
                            .bold()
                    }
                    .font(.system(size: 15, design: .rounded))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    func handleSignUp() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            auth.signUp(email: email, password: password)
            isLoading = false
        }
    }
}
