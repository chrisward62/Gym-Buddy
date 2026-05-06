import SwiftUI

struct TagPill: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(isSelected ? .black : .dumbelleTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dumbelleAccent : Color.dumbelleSurface)
            .cornerRadius(20)
    }
}
