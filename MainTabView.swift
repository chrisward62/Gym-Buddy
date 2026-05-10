import SwiftUI
 
struct MainTabView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "flame.fill")
                }
 
            MatchesView()
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
 
            SessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "calendar")
                }
 
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.dumbelleAccent)
        .preferredColorScheme(.dark)
    }
}
 
