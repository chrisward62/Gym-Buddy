import SwiftUI

enum ButtonVariant {
    case primary, secondary, destructive
}

struct DumbelleButton: View {
    let title: String
    let variant: ButtonVariant
    var isLoading: Bool = false
    let action: () -> Void

    var backgroundColor: Color {
        switch variant {
        case .primary: return .dumbelleAccent
        case .secondary: return .dumbelleSurface
        case .destructive: return .dumbelleDestructive
        }
    }

    var textColor: Color {
        switch variant {
        case .primary: return .black
        case .secondary: return .dumbelleTextPrimary
        case .destructive: return .white
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(16)
        }
        .disabled(isLoading)
    }
}
