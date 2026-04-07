import Foundation

/// Minimal Question/Answer models used by User (expand as needed).
struct Question: Codable, Identifiable, Equatable {
    let id: String
    let authorId: String
    var title: String
    var body: String
    let createdAt: Date
    var editedAt: Date?
    var answers: [Answer] = []
    var votes: Int = 0

    init(id: String = Account.randomId(),
         authorId: String,
         title: String,
         body: String) {
        self.id = id
        self.authorId = authorId
        self.title = title
        self.body = body
        self.createdAt = Date()
    }
}

struct Answer: Codable, Identifiable, Equatable {
    let id: String
    let questionId: String
    let authorId: String
    var content: String
    let createdAt: Date
    var editedAt: Date?
    var votes: Int = 0

    init(id: String = Account.randomId(),
         questionId: String,
         authorId: String,
         content: String) {
        self.id = id
        self.questionId = questionId
        self.authorId = authorId
        self.content = content
        self.createdAt = Date()
    }
}

/// User extends Account and holds questions, answers, badges, reputation.
class User: Account {
    var username: String
    var reputation: Int
    var badges: [ReputationBadge]
    var questions: [Question]
    var answers: [Answer]

    enum CodingKeys: String, CodingKey {
        case id, username, email, passwordHash, salt, verified, isAdmin, sessionToken
        case reputation, badges, questions, answers
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // decode superclass properties
        let id = try container.decode(String.self, forKey: .id)
        let email = try container.decode(String.self, forKey: .email)
        let passwordHash = try container.decode(String.self, forKey: .passwordHash)
        let salt = try container.decode(String.self, forKey: .salt)
        let verified = try container.decode(Bool.self, forKey: .verified)
        let isAdmin = try container.decode(Bool.self, forKey: .isAdmin)
        let sessionToken = try container.decodeIfPresent(String.self, forKey: .sessionToken)

        // decode subclass properties (must initialize before calling super.init)
        self.username = try container.decode(String.self, forKey: .username)
        self.reputation = try container.decodeIfPresent(Int.self, forKey: .reputation) ?? 0
        self.badges = try container.decodeIfPresent([ReputationBadge].self, forKey: .badges) ?? []
        self.questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
        self.answers = try container.decodeIfPresent([Answer].self, forKey: .answers) ?? []

        try super.init(id: id,
                       email: email,
                       passwordHash: passwordHash,
                       salt: salt,
                       verified: verified,
                       isAdmin: isAdmin,
                       sessionToken: sessionToken)
    }

    override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // encode superclass stored properties
        try container.encode(self.id, forKey: .id)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.passwordHash, forKey: .passwordHash)
        try container.encode(self.salt, forKey: .salt)
        try container.encode(self.verified, forKey: .verified)
        try container.encode(self.isAdmin, forKey: .isAdmin)
        try container.encodeIfPresent(self.sessionToken, forKey: .sessionToken)

        // encode subclass properties
        try container.encode(self.username, forKey: .username)
        try container.encode(self.reputation, forKey: .reputation)
        try container.encode(self.badges, forKey: .badges)
        try container.encode(self.questions, forKey: .questions)
        try container.encode(self.answers, forKey: .answers)
    }

    // MARK: - Designated initializer forwarding to Account.

    init(username: String,
         email: String,
         password: String,
         isAdmin: Bool = false) throws {
        self.username = username
        self.reputation = 0
        self.badges = []
        self.questions = []
        self.answers = []
        try super.init(email: email, password: password, isAdmin: isAdmin)
    }

    /// Rehydrate convenience initializer (for DB / Supabase).
    init(id: String,
         username: String,
         email: String,
         passwordHash: String,
         salt: String,
         verified: Bool = false,
         isAdmin: Bool = false,
         sessionToken: String? = nil,
         reputation: Int = 0,
         badges: [ReputationBadge] = [],
         questions: [Question] = [],
         answers: [Answer] = []) {
        self.username = username
        self.reputation = reputation
        self.badges = badges
        self.questions = questions
        self.answers = answers
        super.init(id: id,
                   email: email,
                   passwordHash: passwordHash,
                   salt: salt,
                   verified: verified,
                   isAdmin: isAdmin,
                   sessionToken: sessionToken)
    }

    // MARK: - Question operations

    @discardableResult
    func createQuestion(title: String, body: String) -> Question {
        let q = Question(authorId: self.id, title: title, body: body)
        questions.append(q)
        return q
    }

    @discardableResult
    func removeQuestion(id: String) -> Bool {
        guard let idx = questions.firstIndex(where: { $0.id == id && $0.authorId == self.id }) else { return false }
        questions.remove(at: idx)
        // also remove related answers owned by this user
        answers.removeAll { $0.questionId == id }
        return true
    }

    @discardableResult
    func editQuestion(id: String, newTitle: String? = nil, newBody: String? = nil) -> Bool {
        guard let idx = questions.firstIndex(where: { $0.id == id && $0.authorId == self.id }) else { return false }
        if let t = newTitle { questions[idx].title = t }
        if let b = newBody { questions[idx].body = b }
        questions[idx].editedAt = Date()
        return true
    }

    // MARK: - Answer operations

    @discardableResult
    func submitAnswer(questionId: String, content: String) -> Answer? {
        // ensure question exists
        guard let qIdx = questions.firstIndex(where: { $0.id == questionId }) ?? nil else {
            // question may exist elsewhere; we still create answer locally
            let a = Answer(questionId: questionId, authorId: self.id, content: content)
            answers.append(a)
            return a
        }
        var answer = Answer(questionId: questionId, authorId: self.id, content: content)
        answers.append(answer)
        questions[qIdx].answers.append(answer)
        return answer
    }

    @discardableResult
    func editAnswer(id: String, newContent: String) -> Bool {
        guard let idx = answers.firstIndex(where: { $0.id == id && $0.authorId == self.id }) else { return false }
        answers[idx].content = newContent
        answers[idx].editedAt = Date()
        // update in questions if present
        if let qIdx = questions.firstIndex(where: { $0.id == answers[idx].questionId }),
           let aIdx = questions[qIdx].answers.firstIndex(where: { $0.id == id }) {
            questions[qIdx].answers[aIdx].content = newContent
            questions[qIdx].answers[aIdx].editedAt = Date()
        }
        return true
    }

    @discardableResult
    func deleteAnswer(id: String) -> Bool {
        guard let idx = answers.firstIndex(where: { $0.id == id && $0.authorId == self.id }) else { return false }
        let questionId = answers[idx].questionId
        answers.remove(at: idx)
        if let qIdx = questions.firstIndex(where: { $0.id == questionId }) {
            questions[qIdx].answers.removeAll { $0.id == id }
        }
        return true
    }

    @discardableResult
    func voteAnswer(answerId: String, upvote: Bool = true) -> Bool {
        // find in user's answers (they might vote on others' answers)
        if let idx = answers.firstIndex(where: { $0.id == answerId }) {
            // user voting their own answer – allow but typically you'd block this
            answers[idx].votes += (upvote ? 1 : -1)
            return true
        }
        // try find in owned questions' answers
        for qIdx in questions.indices {
            if let aIdx = questions[qIdx].answers.firstIndex(where: { $0.id == answerId }) {
                questions[qIdx].answers[aIdx].votes += (upvote ? 1 : -1)
                return true
            }
        }
        // not found locally: vote couldn't be applied here
        return false
    }

    // MARK: - Badge operations

    @discardableResult
    func addBadge(_ badge: ReputationBadge) -> Bool {
        if badges.contains(where: { $0.badgeName == badge.badgeName && $0.badgeType == badge.badgeType }) {
            return false
        }
        badges.append(badge)
        reputation += badge.badgeLevel
        return true
    }

    @discardableResult
    func updateBadge(name: String, newLevel: Int? = nil, newDescription: String? = nil) -> Bool {
        guard let idx = badges.firstIndex(where: { $0.badgeName == name }) else { return false }
        if let level = newLevel {
            badges[idx].badgeLevel = level
        }
        if let desc = newDescription {
            badges[idx].badgeDescription = desc
        }
        // recompute reputation (simple strategy)
        reputation = badges.reduce(0) { $0 + $1.badgeLevel }
        return true
    }
}