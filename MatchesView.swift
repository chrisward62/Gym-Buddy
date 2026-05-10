import SwiftUI
import FirebaseFirestore

// MARK: - Models
struct Match: Identifiable, Hashable {
    let id: String
    let partnerId: String
    let partnerName: String
    let partnerInitials: String
    let partnerImageURL: String?
    let accentColor: Color
    var lastMessage: String
    var lastMessageTime: Date?
    var unread: Int

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Match, rhs: Match) -> Bool { lhs.id == rhs.id }

    var timeString: String {
        guard let date = lastMessageTime else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct ChatMessage: Identifiable, Hashable {
    let id: String
    let text: String
    let senderId: String
    let timestamp: Date

    var isFromMe: Bool = false

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Chat View
struct ChatView: View {
    let match: Match
    let currentUserId: String
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var listener: ListenerRegistration? = nil
    @Environment(\.dismiss) var dismiss

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            Color.dumbelleBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.dumbelleAccent)
                    }

                    Circle()
                        .fill(match.accentColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Group {
                                if let urlString = match.partnerImageURL, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Text(match.partnerInitials)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(match.accentColor)
                                    }
                                } else {
                                    Text(match.partnerInitials)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(match.accentColor)
                                }
                            }
                        )
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.partnerName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                        Text("Gym Partner")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.dumbelleTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.dumbelleSurface)

                Divider().background(Color.dumbelleSurface)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { msg in
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Message...", text: $messageText)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.dumbelleSurface)
                        .cornerRadius(24)

                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(messageText.isEmpty ? .dumbelleTextSecondary : .dumbelleAccent)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.dumbelleBackground)
            }
        }
        .navigationBarHidden(true)
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Real-time listener
    func startListening() {
        listener = db.collection("messages")
            .document(match.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let loaded = docs.map { doc -> ChatMessage in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String ?? ""
                    var msg = ChatMessage(
                        id: doc.documentID,
                        text: data["text"] as? String ?? "",
                        senderId: senderId,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    msg.isFromMe = senderId == currentUserId
                    return msg
                }
                DispatchQueue.main.async {
                    messages = loaded
                }
            }
    }

    // MARK: - Send Message
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messageText = ""

        let messageData: [String: Any] = [
            "text": text,
            "senderId": currentUserId,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("messages")
            .document(match.id)
            .collection("messages")
            .addDocument(data: messageData)

        // Update last message on match document
        db.collection("matches").document(match.id).updateData([
            "lastMessage": text,
            "lastMessageTime": Timestamp(date: Date()),
            "lastSenderId": currentUserId
        ])
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromMe { Spacer() }
            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(message.isFromMe ? .black : .dumbelleTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromMe ? Color.dumbelleAccent : Color.dumbelleSurface)
                    .cornerRadius(18)
                Text(message.timeString)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.dumbelleTextSecondary)
            }
            .frame(maxWidth: 260, alignment: message.isFromMe ? .trailing : .leading)
            if !message.isFromMe { Spacer() }
        }
    }
}

// MARK: - Matches List View
struct MatchesView: View {
    @EnvironmentObject var auth: AuthManager
    @State private var matches: [Match] = []
    @State private var selectedMatch: Match? = nil
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var listener: ListenerRegistration? = nil

    private let db = Firestore.firestore()

    var filteredMatches: [Match] {
        if searchText.isEmpty { return matches }
        return matches.filter { $0.partnerName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dumbelleBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Matches")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.dumbelleTextPrimary)
                            Text("\(matches.count) gym partners")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.dumbelleTextSecondary)
                        TextField("Search matches", text: $searchText)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.dumbelleTextPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.dumbelleSurface)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.dumbelleAccent)
                        Spacer()
                    } else if matches.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.dumbelleTextSecondary)
                            Text("No matches yet")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.dumbelleTextPrimary)
                            Text("Start swiping in Discover\nto find gym partners")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        // New matches row
                        VStack(alignment: .leading, spacing: 10) {
                            Text("New Matches")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.dumbelleTextSecondary)
                                .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(matches.prefix(5)) { match in
                                        Button { selectedMatch = match } label: {
                                            VStack(spacing: 6) {
                                                Circle()
                                                    .fill(match.accentColor.opacity(0.2))
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        Group {
                                                            if let urlString = match.partnerImageURL, let url = URL(string: urlString) {
                                                                AsyncImage(url: url) { img in
                                                                    img.resizable().scaledToFill()
                                                                } placeholder: {
                                                                    Text(match.partnerInitials)
                                                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                                                        .foregroundColor(match.accentColor)
                                                                }
                                                            } else {
                                                                Text(match.partnerInitials)
                                                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                                                    .foregroundColor(match.accentColor)
                                                            }
                                                        }
                                                    )
                                                    .clipShape(Circle())
                                                Text(match.partnerName.components(separatedBy: " ").first ?? "")
                                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                                    .foregroundColor(.dumbelleTextSecondary)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 8)

                        Divider().background(Color.dumbelleSurface).padding(.horizontal, 24)

                        // Messages list
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredMatches) { match in
                                    Button { selectedMatch = match } label: {
                                        MatchRow(match: match)
                                    }
                                    Divider()
                                        .background(Color.dumbelleSurface)
                                        .padding(.leading, 80)
                                }
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedMatch) { match in
                ChatView(match: match, currentUserId: auth.uid ?? "")
            }
        }
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
    }

    // MARK: - Real-time Matches Listener
    func startListening() {
        guard let uid = auth.uid else { return }

        listener = db.collection("matches")
            .whereField("userIds", arrayContains: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else {
                    DispatchQueue.main.async { isLoading = false }
                    return
                }

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

                        let match = Match(
                            id: doc.documentID,
                            partnerId: partnerId,
                            partnerName: name,
                            partnerInitials: initials,
                            partnerImageURL: userData["profileImageURL"] as? String,
                            accentColor: color,
                            lastMessage: data["lastMessage"] as? String ?? "You matched! Say hi 👋",
                            lastMessageTime: (data["lastMessageTime"] as? Timestamp)?.dateValue(),
                            unread: 0
                        )
                        loaded.append(match)
                    }
                }

                group.notify(queue: .main) {
                    matches = loaded.sorted { ($0.lastMessageTime ?? Date.distantPast) > ($1.lastMessageTime ?? Date.distantPast) }
                    isLoading = false
                }
            }
    }
}

struct MatchRow: View {
    let match: Match

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(match.accentColor.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    Group {
                        if let urlString = match.partnerImageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Text(match.partnerInitials)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(match.accentColor)
                            }
                        } else {
                            Text(match.partnerInitials)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(match.accentColor)
                        }
                    }
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(match.partnerName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.dumbelleTextPrimary)
                    Spacer()
                    Text(match.timeString)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.dumbelleTextSecondary)
                }
                Text(match.lastMessage)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.dumbelleTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.dumbelleBackground)
    }
}
