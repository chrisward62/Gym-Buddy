import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        if isActive {
            if auth.isAuthenticated {
                if auth.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                        .environmentObject(auth)
                }
            } else {
                LoginView()
            }
        } else {
            ZStack {
                Color.dumbelleBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("🏋️")
                        .font(.system(size: 80))
                    Text("Dumbelle")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleAccent)
                    Text("Find your gym partner")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}
