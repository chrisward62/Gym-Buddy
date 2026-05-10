import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct ProfileView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var isEditing = false
    @State private var showLogoutAlert = false
    @State private var isLoading = true

    // Profile data
    @State private var name = ""
    @State private var age = ""
    @State private var bio = ""
    @State private var gym = ""
    @State private var gymType = ""
    @State private var workoutStyles: [String] = []
    @State private var scheduleDays: [String] = []
    @State private var experienceLevel = ""
    @State private var profileImageURL: String? = nil

    // Stats
    @State private var matchCount = 0
    @State private var sessionCount = 0
    @State private var partnerCount = 0

    private let db = Firestore.firestore()

    var initials: String {
        name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
    }

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.dumbelleAccent)
                    Text("Loading profile...")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {

                        // Header
                        HStack {
                            Text("Profile")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.dumbelleTextPrimary)
                            Spacer()
                            Button {
                                isEditing = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.dumbelleAccent)
                                    .frame(width: 40, height: 40)
                                    .background(Color.dumbelleSurface)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                        // Avatar
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.dumbelleAccent.opacity(0.15))
                                    .frame(width: 100, height: 100)

                                if let urlString = profileImageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Text(initials.isEmpty ? "?" : initials)
                                            .font(.system(size: 38, weight: .black, design: .rounded))
                                            .foregroundColor(.dumbelleAccent)
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else {
                                    Text(initials.isEmpty ? "?" : initials)
                                        .font(.system(size: 38, weight: .black, design: .rounded))
                                        .foregroundColor(.dumbelleAccent)
                                }

                                Circle()
                                    .fill(Color.dumbelleAccent)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                    )
                                    .offset(x: 34, y: 34)
                            }

                            VStack(spacing: 4) {
                                Text(name.isEmpty ? "Your Name" : name)
                                    .font(.system(size: 24, weight: .black, design: .rounded))
                                    .foregroundColor(.dumbelleTextPrimary)
                                Text("Age \(age) · \(gym.isEmpty ? "No gym set" : gym)")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.dumbelleTextSecondary)
                            }

                            if !experienceLevel.isEmpty {
                                Text(experienceLevel)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.dumbelleAccent)
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.bottom, 24)

                        // Stats
                        HStack(spacing: 1) {
                            ProfileStat(value: "\(matchCount)", label: "Matches")
                            Divider().background(Color.dumbelleBackground).frame(height: 40)
                            ProfileStat(value: "\(sessionCount)", label: "Sessions")
                            Divider().background(Color.dumbelleBackground).frame(height: 40)
                            ProfileStat(value: "\(partnerCount)", label: "Partners")
                        }
                        .background(Color.dumbelleSurface)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                        // Bio
                        ProfileCard(title: "About Me") {
                            Text(bio.isEmpty ? "No bio yet — tap edit to add one!" : bio)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(bio.isEmpty ? .dumbelleTextSecondary : .dumbelleTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Gym
                        ProfileCard(title: "Gym Info") {
                            HStack(spacing: 10) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.dumbelleAccent)
                                Text(gym.isEmpty ? "No gym set" : gym)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.dumbelleTextPrimary)
                                Spacer()
                                Text(gymType)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.dumbelleTextSecondary)
                            }
                        }

                        // Schedule
                        if !scheduleDays.isEmpty {
                            ProfileCard(title: "My Schedule") {
                                HStack(spacing: 6) {
                                    ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { day in
                                        let active = scheduleDays.contains(day)
                                        Text(day)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(active ? .black : .dumbelleTextSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(active ? Color.dumbelleAccent : Color.dumbelleBackground)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }

                        // Workout styles
                        if !workoutStyles.isEmpty {
                            ProfileCard(title: "Workout Styles") {
                                FlowLayout(items: workoutStyles) { style in
                                    TagPill(title: style, isSelected: true)
                                }
                            }
                        }

                        // Actions
                        VStack(spacing: 12) {
                            ProfileActionRow(icon: "bell.fill", label: "Notifications", color: .dumbelleAccent) {}
                            ProfileActionRow(icon: "lock.fill", label: "Privacy", color: .blue) {}
                            ProfileActionRow(icon: "questionmark.circle.fill", label: "Help & Support", color: .purple) {}
                            ProfileActionRow(icon: "arrow.right.circle.fill", label: "Log Out", color: .dumbelleDestructive) {
                                showLogoutAlert = true
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            loadProfile()
            loadStats()
        }
        .sheet(isPresented: $isEditing) {
            EditProfileSheet(name: $name, age: $age, bio: $bio, gym: $gym) {
                saveProfile()
            }
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) { auth.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Load Profile
    func loadProfile() {
        guard let uid = auth.uid else { return }
        db.collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            DispatchQueue.main.async {
                name = data["name"] as? String ?? ""
                age = "\(data["age"] as? Int ?? 0)"
                bio = data["bio"] as? String ?? ""
                gym = data["gymName"] as? String ?? ""
                gymType = data["gymType"] as? String ?? ""
                workoutStyles = data["selectedWorkoutStyles"] as? [String] ?? []
                scheduleDays = data["selectedDays"] as? [String] ?? []
                experienceLevel = data["experienceLevel"] as? String ?? ""
                profileImageURL = data["profileImageURL"] as? String
                isLoading = false
            }
        }
    }

    // MARK: - Load Stats
    func loadStats() {
        guard let uid = auth.uid else { return }

        db.collection("matches")
            .whereField("userIds", arrayContains: uid)
            .getDocuments { snapshot, _ in
                DispatchQueue.main.async {
                    matchCount = snapshot?.documents.count ?? 0
                }
            }

        db.collection("sessions")
            .whereField("creatorId", isEqualTo: uid)
            .getDocuments { snapshot, _ in
                let docs = snapshot?.documents ?? []
                let partnerIds = docs.compactMap { $0.data()["partnerId"] as? String }
                DispatchQueue.main.async {
                    sessionCount = docs.count
                    partnerCount = Set(partnerIds).count
                }
            }
    }

    // MARK: - Save Profile
    func saveProfile() {
        guard let uid = auth.uid else { return }
        db.collection("users").document(uid).updateData([
            "name": name,
            "age": Int(age) ?? 0,
            "bio": bio,
            "gymName": gym
        ])
    }
}

// MARK: - Sub-components
struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(.dumbelleAccent)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.dumbelleTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

struct ProfileCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.dumbelleTextSecondary)
                .textCase(.uppercase)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dumbelleSurface)
        .cornerRadius(16)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.12))
                    .cornerRadius(8)
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(label == "Log Out" ? .dumbelleDestructive : .dumbelleTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.dumbelleTextSecondary)
            }
            .padding(14)
            .background(Color.dumbelleSurface)
            .cornerRadius(12)
        }
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var bio: String
    @Binding var gym: String
    let onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dumbelleTextSecondary.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Text("Edit Profile")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.dumbelleTextPrimary)

                VStack(spacing: 16) {
                    DumbelleTextField(placeholder: "Full Name", text: $name)
                    DumbelleTextField(placeholder: "Age", text: $age)
                    DumbelleTextField(placeholder: "Gym name", text: $gym)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dumbelleSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dumbelleTextSecondary.opacity(0.3), lineWidth: 1)
                            )
                        if bio.isEmpty {
                            Text("Short bio...")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                                .padding(16)
                        }
                        TextEditor(text: $bio)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                            .padding(12)
                            .background(Color.clear)
                            .frame(height: 100)
                            .scrollContentBackground(.hidden)
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    DumbelleButton(title: "Save Changes", variant: .primary) {
                        onSave()
                        dismiss()
                    }
                    DumbelleButton(title: "Cancel", variant: .secondary) {
                        dismiss()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}
