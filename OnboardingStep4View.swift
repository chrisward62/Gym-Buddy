import SwiftUI

struct OnboardingStep4View: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                VStack(spacing: 8) {
                    Text("Your workout routine")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("When and how do you train?")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                // Days
                VStack(alignment: .leading, spacing: 12) {
                    Text("Days you work out")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    HStack(spacing: 8) {
                        ForEach(coordinator.days, id: \.self) { day in
                            Button {
                                if coordinator.selectedDays.contains(day) {
                                    coordinator.selectedDays.remove(day)
                                } else {
                                    coordinator.selectedDays.insert(day)
                                }
                            } label: {
                                Text(day)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(coordinator.selectedDays.contains(day) ? .black : .dumbelleTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(coordinator.selectedDays.contains(day) ? Color.dumbelleAccent : Color.dumbelleSurface)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Time Slots
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferred time slots")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    ForEach(coordinator.timeSlots, id: \.self) { slot in
                        Button {
                            if coordinator.selectedTimeSlots.contains(slot) {
                                coordinator.selectedTimeSlots.remove(slot)
                            } else {
                                coordinator.selectedTimeSlots.insert(slot)
                            }
                        } label: {
                            HStack {
                                Text(slot)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.dumbelleTextPrimary)
                                Spacer()
                                if coordinator.selectedTimeSlots.contains(slot) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.dumbelleAccent)
                                }
                            }
                            .padding(16)
                            .background(coordinator.selectedTimeSlots.contains(slot) ? Color.dumbelleSurface : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(coordinator.selectedTimeSlots.contains(slot) ? Color.dumbelleAccent : Color.dumbelleSurface, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }

                // Workout Styles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Workout style")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)

                    FlowLayout(items: coordinator.workoutStyles) { style in
                        Button {
                            if coordinator.selectedWorkoutStyles.contains(style) {
                                coordinator.selectedWorkoutStyles.remove(style)
                            } else {
                                coordinator.selectedWorkoutStyles.insert(style)
                            }
                        } label: {
                            TagPill(title: style, isSelected: coordinator.selectedWorkoutStyles.contains(style))
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
