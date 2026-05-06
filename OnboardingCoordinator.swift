import SwiftUI
import Combine

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep = 1
    let totalSteps = 5

    @Published var name = ""
    @Published var age = ""
    @Published var bio = ""
    @Published var profileImage: UIImage? = nil

    @Published var latitude: Double = 37.7749
    @Published var longitude: Double = -122.4194
    @Published var neighborhood = "Your Area"
    @Published var radius: Double = 10

    @Published var gymName = ""
    @Published var gymType = "Commercial gym"
    let gymTypes = ["Commercial gym", "CrossFit box", "Home gym", "Outdoor", "Multiple"]

    @Published var selectedDays: Set<String> = []
    @Published var selectedTimeSlots: Set<String> = []
    @Published var selectedWorkoutStyles: Set<String> = []
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let timeSlots = ["Morning 5-9am", "Midday 9am-12pm", "Afternoon 12-5pm", "Evening 5-10pm"]
    let workoutStyles = ["Powerlifting", "Bodybuilding", "CrossFit", "HIIT", "Calisthenics",
                         "Cardio", "Olympic Lifting", "Yoga", "Pilates", "Sport-specific"]

    @Published var genderPreference = "Any"
    @Published var experienceLevel = "Any"
    @Published var selectedGoals: Set<String> = []
    let genderOptions = ["Any", "Male", "Female", "Non-binary"]
    let experienceLevels = ["Beginner", "Intermediate", "Advanced", "Any"]
    let goals = ["Lose weight", "Build muscle", "Improve endurance", "Stay active", "Competitive", "Any"]

    func nextStep() {
        if currentStep < totalSteps {
            withAnimation { currentStep += 1 }
        }
    }

    func previousStep() {
        if currentStep > 1 {
            withAnimation { currentStep -= 1 }
        }
    }

    func complete() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
}
