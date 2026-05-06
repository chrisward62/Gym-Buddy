import SwiftUI

struct OnboardingStep1View: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                VStack(spacing: 8) {
                    Text("Let's set up your profile")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("Tell us a bit about yourself")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                // Photo Picker
                ImagePicker(image: $coordinator.profileImage)

                // Fields
                VStack(spacing: 16) {
                    DumbelleTextField(placeholder: "Full Name", text: $coordinator.name)
                    DumbelleTextField(placeholder: "Age", text: $coordinator.age)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dumbelleSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dumbelleTextSecondary.opacity(0.3), lineWidth: 1)
                            )

                        if coordinator.bio.isEmpty {
                            Text("Short bio (e.g. 'Powerlifter chasing PRs')")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                                .padding(16)
                        }

                        TextEditor(text: $coordinator.bio)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                            .padding(12)
                            .background(Color.clear)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                    }
                    .frame(height: 100)
                    .onChange(of: coordinator.bio) { newValue in
                        if newValue.count > 120 {
                            coordinator.bio = String(newValue.prefix(120))
                        }
                    }
                }

                DumbelleButton(title: "Next", variant: .primary) {
                    coordinator.nextStep()
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
