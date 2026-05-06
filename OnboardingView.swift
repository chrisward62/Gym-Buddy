import SwiftUI

struct OnboardingView: View {
    @StateObject var coordinator = OnboardingCoordinator()
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Step \(coordinator.currentStep) of \(coordinator.totalSteps)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                        Spacer()
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dumbelleSurface)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.dumbelleAccent)
                                .frame(width: geo.size.width * CGFloat(coordinator.currentStep) / CGFloat(coordinator.totalSteps), height: 6)
                                .animation(.spring(), value: coordinator.currentStep)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Step Content
                Group {
                    switch coordinator.currentStep {
                    case 1: OnboardingStep1View()
                    case 2: OnboardingStep2View()
                    case 3: OnboardingStep3View()
                    case 4: OnboardingStep4View()
                    case 5: OnboardingStep5View()
                    default: EmptyView()
                    }
                }
                .environmentObject(coordinator)
            }
        }
    }
}
