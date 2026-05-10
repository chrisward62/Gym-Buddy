import SwiftUI
import FirebaseFirestore

// MARK: - Data Model
struct GymPartner: Identifiable {
    let id: String
    let name: String
    let age: Int
    let gym: String
    let bio: String
    let workoutStyles: [String]
    let experienceLevel: String
    let profileImageURL: String?

    var initials: String {
        name.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
    }

    var accentColor: Color {
        let colors: [Color] = [.blue, .purple, .orange, .green, .red, .cyan]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Card View
struct PartnerCard: View {
    let partner: GymPartner
    let dragOffset: CGSize
    let rotation: Double

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.dumbelleSurface)

            // Avatar area
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(partner.accentColor.opacity(0.12))

                VStack {
                    if let urlString = partner.profileImageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            initialsCircle
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .padding(.top, 60)
                    } else {
                        initialsCircle
                            .padding(.top, 60)
                    }
                    Spacer()
                }
            }

            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.dumbelleBackground.opacity(0.95)],
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(24)

            // Info
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(partner.name)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                    Text("\(partner.age)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleAccent)
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.dumbelleAccent)
                    Text(partner.gym.isEmpty ? "No gym set" : partner.gym)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }

                Text(partner.bio.isEmpty ? "No bio yet." : partner.bio)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.dumbelleTextSecondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    ForEach(partner.workoutStyles.prefix(2), id: \.self) { style in
                        Text(style)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dumbelleAccent)
                            .cornerRadius(20)
                    }
                    if !partner.experienceLevel.isEmpty {
                        Text(partner.experienceLevel)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dumbelleBackground)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(20)

            // Like overlay
            if dragOffset.width > 30 {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.green.opacity(min(Double(dragOffset.width) / 150.0, 0.35)))
                    .cornerRadius(24)
                HStack {
                    VStack {
                        Text("CONNECT")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.green)
                            .padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green, lineWidth: 3))
                            .rotationEffect(.degrees(-15))
                            .padding(24)
                        Spacer()
                    }
                    Spacer()
                }
            } else if dragOffset.width < -30 {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.red.opacity(min(Double(-dragOffset.width) / 150.0, 0.35)))
                    .cornerRadius(24)
                HStack {
                    Spacer()
                    VStack {
                        Text("PASS")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.red)
                            .padding(10)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 3))
                            .rotationEffect(.degrees(15))
                            .padding(24)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 520)
        .rotationEffect(.degrees(rotation))
        .offset(dragOffset)
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
    }

    var initialsCircle: some View {
        Circle()
            .fill(partner.accentColor.opacity(0.25))
            .frame(width: 120, height: 120)
            .overlay(
                Text(partner.initials)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(partner.accentColor)
            )
    }
}

// MARK: - Discover View
struct DiscoverView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var partners: [GymPartner] = []
    @State private var dragOffset: CGSize = .zero
    @State private var matchedName: String? = nil
    @State private var showMatch = false
    @State private var isLoading = true
    @State private var seenUserIds: Set<String> = []

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Discover")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Gym partners near you")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                    Spacer()
                    Button {
                        loadPartners()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.dumbelleAccent)
                            .frame(width: 44, height: 44)
                            .background(Color.dumbelleSurface)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)

                if isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView().tint(.dumbelleAccent)
                        Text("Finding gym partners...")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                    Spacer()
                } else if partners.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.dumbelleTextSecondary)
                        Text("No more partners\nnearby right now")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                            .multilineTextAlignment(.center)
                        Text("Check back later or expand\nyour search radius in Settings")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                            .multilineTextAlignment(.center)
                        DumbelleButton(title: "Refresh", variant: .primary) {
                            loadPartners()
                        }
                        .frame(width: 160)
                    }
                    Spacer()
                } else {
                    // Card stack
                    ZStack {
                        ForEach(Array(partners.enumerated().reversed()), id: \.element.id) { index, partner in
                            let isTop = index == partners.count - 1
                            let scale = isTop ? 1.0 : CGFloat(1.0 - Double(partners.count - 1 - index) * 0.04)
                            let yOffset = isTop ? 0.0 : CGFloat(Double(partners.count - 1 - index) * -12)

                            PartnerCard(
                                partner: partner,
                                dragOffset: isTop ? dragOffset : .zero,
                                rotation: isTop ? Double(dragOffset.width) / 20.0 : 0
                            )
                            .scaleEffect(scale)
                            .offset(y: yOffset)
                            .gesture(isTop ? dragGesture : nil)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Action buttons
                    HStack(spacing: 24) {
                        Button { swipe(direction: -1) } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.dumbelleDestructive)
                                .frame(width: 64, height: 64)
                                .background(Color.dumbelleSurface)
                                .clipShape(Circle())
                                .shadow(color: .dumbelleDestructive.opacity(0.3), radius: 8)
                        }

                        Button {} label: {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.dumbelleAccent)
                                .frame(width: 50, height: 50)
                                .background(Color.dumbelleSurface)
                                .clipShape(Circle())
                        }

                        Button { swipe(direction: 1) } label: {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.green)
                                .frame(width: 64, height: 64)
                                .background(Color.dumbelleSurface)
                                .clipShape(Circle())
                                .shadow(color: .green.opacity(0.3), radius: 8)
                        }
                    }
                    .padding(.vertical, 24)
                }
            }

            // Match overlay
            if showMatch, let name = matchedName {
                Color.black.opacity(0.85).ignoresSafeArea()
                    .transition(.opacity)
                VStack(spacing: 20) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.dumbelleAccent)
                    Text("It's a Match!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.dumbelleAccent)
                    Text("You and \(name) both\nwant to train together")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 12) {
                        DumbelleButton(title: "Send a Message", variant: .primary) {
                            showMatch = false
                        }
                        DumbelleButton(title: "Keep Discovering", variant: .secondary) {
                            showMatch = false
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear { loadPartners() }
        .animation(.spring(response: 0.3), value: showMatch)
    }

    // MARK: - Drag Gesture
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = value.translation }
            .onEnded { value in
                if value.translation.width > 120 {
                    swipe(direction: 1)
                } else if value.translation.width < -120 {
                    swipe(direction: -1)
                } else {
                    withAnimation(.spring()) { dragOffset = .zero }
                }
            }
    }

    // MARK: - Swipe
    func swipe(direction: CGFloat) {
        guard !partners.isEmpty else { return }
        let partner = partners.last!

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            dragOffset = CGSize(width: direction * 600, height: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            partners.removeLast()
            dragOffset = .zero
            seenUserIds.insert(partner.id)

            if direction > 0 {
                createMatch(with: partner)
            }
        }
    }

    // MARK: - Load Partners
    func loadPartners() {
        guard let uid = auth.uid else { return }
        isLoading = true

        db.collection("users")
            .whereField("onboardingComplete", isEqualTo: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                guard let docs = snapshot?.documents else {
                    DispatchQueue.main.async { isLoading = false }
                    return
                }

                let loaded = docs.compactMap { doc -> GymPartner? in
                    let data = doc.data()
                    let id = doc.documentID

                    // Exclude current user and already seen users
                    guard id != uid, !seenUserIds.contains(id) else { return nil }

                    return GymPartner(
                        id: id,
                        name: data["name"] as? String ?? "Unknown",
                        age: data["age"] as? Int ?? 0,
                        gym: data["gymName"] as? String ?? "",
                        bio: data["bio"] as? String ?? "",
                        workoutStyles: data["selectedWorkoutStyles"] as? [String] ?? [],
                        experienceLevel: data["experienceLevel"] as? String ?? "",
                        profileImageURL: data["profileImageURL"] as? String
                    )
                }

                DispatchQueue.main.async {
                    partners = loaded.shuffled()
                    isLoading = false
                }
            }
    }

    // MARK: - Create Match
    func createMatch(with partner: GymPartner) {
        guard let uid = auth.uid else { return }

        // Check if match already exists
        db.collection("matches")
            .whereField("userIds", arrayContains: uid)
            .getDocuments { snapshot, _ in
                let alreadyMatched = snapshot?.documents.contains { doc in
                    let ids = doc.data()["userIds"] as? [String] ?? []
                    return ids.contains(partner.id)
                } ?? false

                guard !alreadyMatched else { return }

                // Create match document
                let matchData: [String: Any] = [
                    "userIds": [uid, partner.id],
                    "createdAt": Timestamp(date: Date())
                ]

                self.db.collection("matches").addDocument(data: matchData) { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            self.matchedName = partner.name
                            withAnimation { self.showMatch = true }
                        }
                    }
                }
            }
    }
}
