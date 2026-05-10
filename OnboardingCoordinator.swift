import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep = 1
    let totalSteps = 5

    // Step 1 — Profile
    @Published var name = ""
    @Published var age = ""
    @Published var bio = ""
    @Published var profileImage: UIImage? = nil

    // Step 2 — Location
    @Published var latitude: Double = 37.7749
    @Published var longitude: Double = -122.4194
    @Published var neighborhood = "Your Area"
    @Published var radius: Double = 10

    // Step 3 — Gym
    @Published var gymName = ""
    @Published var gymType = "Commercial gym"
    let gymTypes = ["Commercial gym", "CrossFit box", "Home gym", "Outdoor", "Multiple"]

    // Step 4 — Schedule
    @Published var selectedDays: Set<String> = []
    @Published var selectedTimeSlots: Set<String> = []
    @Published var selectedWorkoutStyles: Set<String> = []
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let timeSlots = ["Morning 5-9am", "Midday 9am-12pm", "Afternoon 12-5pm", "Evening 5-10pm"]
    let workoutStyles = ["Powerlifting", "Bodybuilding", "CrossFit", "HIIT", "Calisthenics",
                         "Cardio", "Olympic Lifting", "Yoga", "Pilates", "Sport-specific"]

    // Step 5 — Preferences
    @Published var genderPreference = "Any"
    @Published var experienceLevel = "Any"
    @Published var selectedGoals: Set<String> = []
    let genderOptions = ["Any", "Male", "Female", "Non-binary"]
    let experienceLevels = ["Beginner", "Intermediate", "Advanced", "Any"]
    let goals = ["Lose weight", "Build muscle", "Improve endurance", "Stay active", "Competitive", "Any"]

    // Save state
    @Published var isSaving = false
    @Published var saveError = ""

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

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

    // MARK: - Complete Onboarding
    func complete(auth: AuthManager, completion: @escaping (Bool) -> Void) {
        guard let uid = auth.uid else {
            saveError = "Not logged in"
            completion(false)
            return
        }

        isSaving = true
        saveError = ""

        if let image = profileImage {
            uploadProfileImage(uid: uid, image: image) { [weak self] imageURL in
                guard let self = self else { return }
                self.saveUserData(uid: uid, imageURL: imageURL, auth: auth, completion: completion)
            }
        } else {
            saveUserData(uid: uid, imageURL: nil, auth: auth, completion: completion)
        }
    }

    // MARK: - Upload Profile Image
    private func uploadProfileImage(uid: String, image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }

        let ref = storage.reference().child("profile_images/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                print("Image upload error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            ref.downloadURL { url, error in
                completion(url?.absoluteString)
            }
        }
    }

    // MARK: - Save User Data to Firestore
    private func saveUserData(uid: String, imageURL: String?, auth: AuthManager, completion: @escaping (Bool) -> Void) {
        var data: [String: Any] = [
            "uid": uid,
            "email": auth.currentUser?.email ?? "",
            "name": name,
            "age": Int(age) ?? 0,
            "bio": bio,
            "gymName": gymName,
            "gymType": gymType,
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "selectedDays": Array(selectedDays),
            "selectedTimeSlots": Array(selectedTimeSlots),
            "selectedWorkoutStyles": Array(selectedWorkoutStyles),
            "genderPreference": genderPreference,
            "experienceLevel": experienceLevel,
            "selectedGoals": Array(selectedGoals),
            "onboardingComplete": true,
            "createdAt": Timestamp(date: Date())
        ]

        if let imageURL = imageURL {
            data["profileImageURL"] = imageURL
        }

        db.collection("users").document(uid).setData(data) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    self.saveError = error.localizedDescription
                    completion(false)
                } else {
                    auth.hasCompletedOnboarding = true
                    completion(true)
                }
            }
        }
    }
}
