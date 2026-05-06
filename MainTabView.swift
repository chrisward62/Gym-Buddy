import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Home")
                .tabItem {
                    Label("Discover", systemImage: "flame.fill")
                }

            Text("Matches")
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }

            Text("Sessions")
                .tabItem {
                    Label("Sessions", systemImage: "calendar")
                }

            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.dumbelleAccent)
        .preferredColorScheme(.dark)
    }
}
