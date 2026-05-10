import SwiftUI
import FirebaseFirestore

// MARK: - Model
struct GymSession: Identifiable, Hashable {
    let id: String
    var partnerName: String
    var partnerId: String
    var partnerInitials: String
    var partnerAccent: Color
    var gym: String
    var date: Date
    var timeSlot: String
    var workoutType: String
    var status: SessionStatus

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: GymSession, rhs: GymSession) -> Bool { lhs.id == rhs.id }
}

enum SessionStatus: String {
    case upcoming = "upcoming"
    case confirmed = "confirmed"
    case completed = "completed"
    case cancelled = "cancelled"

    var label: String {
        switch self {
        case .upcoming: return "Pending"
        case .confirmed: return "Confirmed"
        case .completed: return "Done"
        case .cancelled: return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .upcoming: return .orange
        case .confirmed: return .green
        case .completed: return .dumbelleTextSecondary
        case .cancelled: return .dumbelleDestructive
        }
    }
}

// MARK: - Sessions View
struct SessionsView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var sessions: [GymSession] = []
    @State private var matches: [Match] = []
    @State private var selectedFilter: SessionFilter = .upcoming
    @State private var showSchedule = false
    @State private var isLoading = true
    @State private var listener: ListenerRegistration? = nil

    private let db = Firestore.firestore()

    enum SessionFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
    }

    var filtered: [GymSession] {
        let now = Date()
        switch selectedFilter {
        case .upcoming:
            return sessions
                .filter { $0.date >= now && $0.status != .cancelled && $0.status != .completed }
                .sorted { $0.date < $1.date }
        case .past:
            return sessions
                .filter { $0.date < now || $0.status == .completed || $0.status == .cancelled }
                .sorted { $0.date > $1.date }
        }
    }

    var upcomingCount: Int {
        sessions.filter { $0.date >= Date() && ($0.status == .upcoming || $0.status == .confirmed) }.count
    }

    var completedCount: Int {
        sessions.filter { $0.status == .completed }.count
    }

    var partnerCount: Int {
        Set(sessions.map { $0.partnerId }).count
    }

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sessions")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Your scheduled workouts")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                    Spacer()
                    Button { showSchedule = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.dumbelleAccent)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Stats
                HStack(spacing: 12) {
                    StatTile(value: "\(upcomingCount)", label: "Upcoming", color: .dumbelleAccent)
                    StatTile(value: "\(completedCount)", label: "Completed", color: .green)
                    StatTile(value: "\(partnerCount)", label: "Partners", color: .blue)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Filter pills
                HStack(spacing: 8) {
                    ForEach(SessionFilter.allCases, id: \.self) { filter in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedFilter == filter ? .black : .dumbelleTextSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(selectedFilter == filter ? Color.dumbelleAccent : Color.dumbelleSurface)
                                .cornerRadius(20)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                if isLoading {
                    Spacer()
                    ProgressView().tint(.dumbelleAccent)
                    Spacer()
                } else if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.dumbelleTextSecondary)
                        Text("No \(selectedFilter.rawValue.lowercased()) sessions")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Schedule a session with\none of your gym partners")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                            .multilineTextAlignment(.center)
                        DumbelleButton(title: "Schedule Session", variant: .primary) {
                            showSchedule = true
                        }
                        .frame(width: 200)
                        .padding(.top, 8)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { session in
                                SessionCard(session: session) {
                                    cancelSession(session)
                                } onConfirm: {
                                    confirmSession(session)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            startListening()
            loadMatches()
        }
        .onDisappear { listener?.remove() }
        .sheet(isPresented: $showSchedule) {
            ScheduleSessionSheet(matches: matches) { partnerName, partnerId, gym, date, workoutType in
                createSession(partnerName: partnerName, partnerId: partnerId, gym: gym, date: date, workoutType: workoutType)
            }
        }
    }

    // MARK: - Load Matches (for scheduling)
    func loadMatches() {
        guard let uid = auth.uid else { return }
        db.collection("matches")
            .whereField("userIds", arrayContains: uid)
            .getDocuments { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let group = DispatchGroup()
                var loaded: [Match] = []

                for doc in docs {
                    let data = doc.data()
                    let userIds = data["userIds"] as? [String] ?? []
                    guard let partnerId = userIds.first(where: { $0 != uid }) else { continue }

                    group.enter()
                    self.db.collection("users").document(partnerId).getDocument { userSnap, _ in
                        defer { group.leave() }
                        guard let userData = userSnap?.data() else { return }
                        let name = userData["name"] as? String ?? "Unknown"
                        let initials = name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
                        let colors: [Color] = [.blue, .purple, .orange, .green, .red, .cyan]
                        let color = colors[abs(partnerId.hashValue) % colors.count]
                        loaded.append(Match(
                            id: doc.documentID,
                            partnerId: partnerId,
                            partnerName: name,
                            partnerInitials: initials,
                            partnerImageURL: userData["profileImageURL"] as? String,
                            accentColor: color,
                            lastMessage: "",
                            lastMessageTime: nil,
                            unread: 0
                        ))
                    }
                }
                group.notify(queue: .main) { matches = loaded }
            }
    }

    // MARK: - Real-time Sessions Listener
    func startListening() {
        guard let uid = auth.uid else { return }

        listener = db.collection("sessions")
            .whereField("creatorId", isEqualTo: uid)
            .order(by: "date", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else {
                    DispatchQueue.main.async { isLoading = false }
                    return
                }

                let loaded = docs.compactMap { doc -> GymSession? in
                    let data = doc.data()
                    guard let timestamp = data["date"] as? Timestamp else { return nil }
                    let partnerId = data["partnerId"] as? String ?? ""
                    let partnerName = data["partnerName"] as? String ?? "Unknown"
                    let initials = partnerName.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
                    let colors: [Color] = [.blue, .purple, .orange, .green, .red, .cyan]
                    let color = colors[abs(partnerId.hashValue) % colors.count]
                    let statusRaw = data["status"] as? String ?? "upcoming"

                    return GymSession(
                        id: doc.documentID,
                        partnerName: partnerName,
                        partnerId: partnerId,
                        partnerInitials: initials,
                        partnerAccent: color,
                        gym: data["gym"] as? String ?? "",
                        date: timestamp.dateValue(),
                        timeSlot: data["timeSlot"] as? String ?? "",
                        workoutType: data["workoutType"] as? String ?? "",
                        status: SessionStatus(rawValue: statusRaw) ?? .upcoming
                    )
                }

                DispatchQueue.main.async {
                    sessions = loaded
                    isLoading = false
                }
            }
    }

    // MARK: - Create Session
    func createSession(partnerName: String, partnerId: String, gym: String, date: Date, workoutType: String) {
        guard let uid = auth.uid else { return }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeSlot = formatter.string(from: date)

        let data: [String: Any] = [
            "creatorId": uid,
            "partnerId": partnerId,
            "partnerName": partnerName,
            "gym": gym,
            "date": Timestamp(date: date),
            "timeSlot": timeSlot,
            "workoutType": workoutType,
            "status": SessionStatus.upcoming.rawValue,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("sessions").addDocument(data: data)
    }

    // MARK: - Cancel Session
    func cancelSession(_ session: GymSession) {
        db.collection("sessions").document(session.id).updateData([
            "status": SessionStatus.cancelled.rawValue
        ])
    }

    // MARK: - Confirm Session
    func confirmSession(_ session: GymSession) {
        db.collection("sessions").document(session.id).updateData([
            "status": SessionStatus.confirmed.rawValue
        ])
    }
}

// MARK: - Stat Tile
struct StatTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.dumbelleTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.dumbelleSurface)
        .cornerRadius(12)
    }
}

// MARK: - Session Card
struct SessionCard: View {
    let session: GymSession
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @State private var showCancel = false

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: session.date)
    }

    var isUpcoming: Bool {
        session.date >= Date() && session.status != .cancelled && session.status != .completed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(session.partnerAccent.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(session.partnerInitials)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(session.partnerAccent)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.partnerName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                    Text(session.workoutType)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                Spacer()

                Text(session.status.label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(session.status.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(session.status.color.opacity(0.15))
                    .cornerRadius(20)
            }

            Divider().background(Color.dumbelleBackground)

            HStack(spacing: 20) {
                Label(dateString, systemImage: "calendar")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.dumbelleTextSecondary)
                Label(session.timeSlot, systemImage: "clock")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.dumbelleTextSecondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "mappin.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.dumbelleAccent)
                Text(session.gym.isEmpty ? "Location TBD" : session.gym)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.dumbelleTextSecondary)
            }

            if isUpcoming {
                HStack(spacing: 8) {
                    if session.status == .upcoming {
                        DumbelleButton(title: "Confirm", variant: .secondary) {
                            onConfirm()
                        }
                    }
                    DumbelleButton(title: "Cancel", variant: .destructive) {
                        showCancel = true
                    }
                }
                .frame(height: 44)
            }
        }
        .padding(16)
        .background(Color.dumbelleSurface)
        .cornerRadius(16)
        .confirmationDialog("Cancel Session?", isPresented: $showCancel) {
            Button("Cancel Session", role: .destructive) { onCancel() }
            Button("Keep It", role: .cancel) {}
        }
    }
}

// MARK: - Schedule Session Sheet
struct ScheduleSessionSheet: View {
    let matches: [Match]
    let onSave: (String, String, String, Date, String) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var selectedMatchIndex = 0
    @State private var gym = ""
    @State private var date = Date()
    @State private var workoutType = "Powerlifting"

    let workoutTypes = ["Powerlifting", "Bodybuilding", "HIIT", "CrossFit", "Cardio", "Legs", "Chest Day", "Back Day", "Arms"]

    var selectedMatch: Match? {
        matches.isEmpty ? nil : matches[selectedMatchIndex]
    }

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.dumbelleTextSecondary.opacity(0.4))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Text("Schedule a Session")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.dumbelleTextPrimary)

                if matches.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.dumbelleTextSecondary)
                        Text("No matches yet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Swipe on some gym partners first\nbefore scheduling a session")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    Spacer()
                    DumbelleButton(title: "Close", variant: .secondary) { dismiss() }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                } else {
                    VStack(spacing: 16) {
                        // Partner picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Partner")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(matches.indices, id: \.self) { i in
                                        Button {
                                            selectedMatchIndex = i
                                        } label: {
                                            Text(matches[i].partnerName)
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundColor(selectedMatchIndex == i ? .black : .dumbelleTextSecondary)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(selectedMatchIndex == i ? Color.dumbelleAccent : Color.dumbelleSurface)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }

                        // Gym
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gym")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                            DumbelleTextField(placeholder: "Gym name", text: $gym)
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                            DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(.dumbelleAccent)
                        }

                        // Workout type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workout Type")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(workoutTypes, id: \.self) { type in
                                        Button { workoutType = type } label: {
                                            TagPill(title: type, isSelected: workoutType == type)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    VStack(spacing: 12) {
                        DumbelleButton(title: "Schedule Session", variant: .primary) {
                            if let match = selectedMatch {
                                onSave(match.partnerName, match.partnerId, gym, date, workoutType)
                                dismiss()
                            }
                        }
                        DumbelleButton(title: "Cancel", variant: .secondary) { dismiss() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}
