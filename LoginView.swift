import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showSignUp = false
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
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Log in to find your gym partner")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                    .padding(.top, 60)

                    // Fields
                    VStack(spacing: 16) {
                        DumbelleTextField(placeholder: "Email", text: $email, isSecure: false)
                        DumbelleTextField(placeholder: "Password", text: $password, isSecure: true)
                    }

                    // Error
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.dumbelleDestructive)
                    }

                    // Login Button
                    DumbelleButton(title: "Log In", variant: .primary, isLoading: isLoading) {
                        handleLogin()
                    }

                    // Divider
                    HStack {
                        Rectangle().fill(Color.dumbelleSurface).frame(height: 1)
                        Text("or")
                            .foregroundColor(.dumbelleTextSecondary)
                            .font(.system(size: 13))
                        Rectangle().fill(Color.dumbelleSurface).frame(height: 1)
                    }

                    // Sign Up
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Don't have an account? ")
                            .foregroundColor(.dumbelleTextSecondary)
                        + Text("Sign Up")
                            .foregroundColor(.dumbelleAccent)
                            .bold()
                    }
                    .font(.system(size: 15, design: .rounded))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(auth)
        }
    }

    func handleLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            auth.login(email: email, password: password)
            isLoading = false
        }
    }
}
