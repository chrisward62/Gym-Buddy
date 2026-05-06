import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false

    static let shared = AuthManager()

    init() {
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }

    func login(email: String, password: String) {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        isAuthenticated = true
    }

    func signUp(email: String, password: String) {
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        isAuthenticated = true
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        UserDefaults.standard.set(false, forKey: "onboardingComplete")
        isAuthenticated = false
        hasCompletedOnboarding = false
    }
}
