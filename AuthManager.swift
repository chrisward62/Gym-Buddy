import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var currentUser: FirebaseAuth.User? = nil
    @Published var errorMessage = ""

    static let shared = AuthManager()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentUser = user
                self.isAuthenticated = user != nil
                if let uid = user?.uid {
                    self.checkOnboardingStatus(uid: uid)
                } else {
                    self.hasCompletedOnboarding = false
                }
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, completion: @escaping (Bool) -> Void) {
        errorMessage = ""
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        errorMessage = ""
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }

    // MARK: - Logout
    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.hasCompletedOnboarding = false
                self.currentUser = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Check Onboarding
    func checkOnboardingStatus(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let data = snapshot?.data(), data["onboardingComplete"] as? Bool == true {
                    self.hasCompletedOnboarding = true
                } else {
                    self.hasCompletedOnboarding = false
                }
            }
        }
    }

    // MARK: - Current User ID
    var uid: String? {
        return Auth.auth().currentUser?.uid
    }
}
