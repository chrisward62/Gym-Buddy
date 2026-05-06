import SwiftUI

struct OnboardingStep3View: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                VStack(spacing: 8) {
                    Text("Where do you train?")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("Tell us about your gym")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                DumbelleTextField(placeholder: "Gym name (e.g. Gold's Gym)", text: $coordinator.gymName)

                // Gym Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gym Type")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    ForEach(coordinator.gymTypes, id: \.self) { type in
                        Button {
                            coordinator.gymType = type
                        } label: {
                            HStack {
                                Text(type)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.dumbelleTextPrimary)
                                Spacer()
                                if coordinator.gymType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.dumbelleAccent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.dumbelleTextSecondary)
                                }
                            }
                            .padding(16)
                            .background(coordinator.gymType == type ? Color.dumbelleSurface : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(coordinator.gymType == type ? Color.dumbelleAccent : Color.dumbelleSurface, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }

                HStack(spacing: 12) {
                    DumbelleButton(title: "Back", variant: .secondary) {
                        coordinator.previousStep()
                    }
                    DumbelleButton(title: "Next", variant: .primary) {
                        coordinator.nextStep()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
