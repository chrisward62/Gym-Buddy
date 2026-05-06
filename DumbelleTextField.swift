import SwiftUI

struct DumbelleTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dumbelleSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dumbelleTextSecondary.opacity(0.3), lineWidth: 1)
                )
                .frame(height: 56)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.dumbelleTextPrimary)
                    .padding(.horizontal, 16)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.dumbelleTextPrimary)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 56)
    }
}
