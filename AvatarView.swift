import SwiftUI

struct AvatarView: View {
    var imageURL: String? = nil
    var initials: String = "?"
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.dumbelleSurface)
                .frame(width: size, height: size)

            if let url = imageURL, let validURL = URL(string: url) {
                AsyncImage(url: validURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    initialsView
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initialsView
            }
        }
    }

    var initialsView: some View {
        Text(initials)
            .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
            .foregroundColor(.dumbelleAccent)
    }
}
