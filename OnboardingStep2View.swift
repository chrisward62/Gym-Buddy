import SwiftUI
import MapKit

struct OnboardingStep2View: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                VStack(spacing: 8) {
                    Text("Where are you based?")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .multilineTextAlignment(.center)
                    Text("We'll find gym partners near you")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                // Map
                ZStack {
                    Map(position: $position)
                        .frame(height: 220)
                        .cornerRadius(16)

                    Image(systemName: "mappin.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.dumbelleAccent)
                }

                // Radius Slider
                VStack(spacing: 12) {
                    HStack {
                        Text("Search Radius")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Spacer()
                        Text("\(Int(coordinator.radius)) miles")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.dumbelleAccent)
                    }
                    Slider(value: $coordinator.radius, in: 1...25, step: 1)
                        .tint(.dumbelleAccent)
                }
                .padding(16)
                .background(Color.dumbelleSurface)
                .cornerRadius(12)

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
