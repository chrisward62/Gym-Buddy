import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Dumbelle 🏋️")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.dumbelleAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.dumbelleBackground)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
