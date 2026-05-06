import SwiftUI

@main
struct DumbelleApp: App {
    @StateObject var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
        }
    }
}
