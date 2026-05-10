import SwiftUI
import Firebase

@main
struct DumbelleApp: App {
    @StateObject var auth = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
        }
    }
}
