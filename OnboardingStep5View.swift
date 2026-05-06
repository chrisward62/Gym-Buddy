import SwiftUI

struct OnboardingStep5View: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                VStack(spacing: 8) {
                    Text("Partner preferences")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("What are you looking for?")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                // Gender Preference
                VStack(alignment: .leading, spacing: 12) {
                    Text("Partner gender")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    HStack(spacing: 8) {
                        ForEach(coordinator.genderOptions, id: \.self) { option in
                            Button {
                                coordinator.genderPreference = option
                            } label: {
                                Text(option)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(coordinator.genderPreference == option ? .black : .dumbelleTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(coordinator.genderPreference == option ? Color.dumbelleAccent : Color.dumbelleSurface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Experience Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Experience level")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    HStack(spacing: 8) {
                        ForEach(coordinator.experienceLevels, id: \.self) { level in
                            Button {
                                coordinator.experienceLevel = level
                            } label: {
                                Text(level)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(coordinator.experienceLevel == level ? .black : .dumbelleTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(coordinator.experienceLevel == level ? Color.dumbelleAccent : Color.dumbelleSurface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Goals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your goals")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    FlowLayout(items: coordinator.goals) { goal in
                        Button {
                            if coordinator.selectedGoals.contains(goal) {
                                coordinator.selectedGoals.remove(goal)
                            } else {
                                coordinator.selectedGoals.insert(goal)
                            }
                        } label: {
                            TagPill(title: goal, isSelected: coordinator.selectedGoals.contains(goal))
                        }
                    }
                }

                DumbelleButton(title: "Find My Gym Partners 🏋️", variant: .primary) {
                    coordinator.complete()
                    auth.hasCompletedOnboarding = true
                }
                .padding(.top, 8)

                Button {
                    coordinator.previousStep()
                } label: {
                    Text("Back")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
