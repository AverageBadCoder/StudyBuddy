import Foundation

/// Answer model used by Question (can be stored inline or referenced by id).
public struct Answer: Codable, Identifiable, Equatable {
    public let id: String
    public let questionId: String
    public let authorId: String
    public var content: String
    public let createdAt: Date
    public var editedAt: Date?
    public var votes: Int

    public init(id: String = Account.randomId(),
                questionId: String,
                authorId: String,
                content: String) {
        self.id = id
        self.questionId = questionId
        self.authorId = authorId
        self.content = content
        self.createdAt = Date()
        self.editedAt = nil
        self.votes = 0
    }
}

/// Question model for creating and managing questions.
public struct Question: Codable, Identifiable, Equatable {
    public let id: String
    public let authorId: String
    public var title: String
    public var body: String
    public let createdAt: Date
    public var editedAt: Date?
    /// Inline answers; replace with [String] ids if you prefer referencing elsewhere.
    public var answers: [Answer]
    public var votes: Int
    public var courseID: String?
    public var deadline: Date?

    public init(id: String = Account.randomId(),
                authorId: String,
                title: String,
                body: String,
                courseID: String? = nil,
                deadline: Date? = nil) {
        self.id = id
        self.authorId = authorId
        self.title = title
        self.body = body
        self.createdAt = Date()
        self.editedAt = nil
        self.answers = []
        self.votes = 0
        self.courseID = courseID
        self.deadline = deadline
    }

    // MARK: - Question operations

    @discardableResult
    public mutating func addAnswer(authorId: String, content: String) -> Answer {
        let a = Answer(questionId: self.id, authorId: authorId, content: content)
        answers.append(a)
        return a
    }

    @discardableResult
    public mutating func removeAnswer(byId answerId: String) -> Bool {
        guard let idx = answers.firstIndex(where: { $0.id == answerId }) else { return false }
        answers.remove(at: idx)
        return true
    }

    @discardableResult
    public mutating func editAnswer(answerId: String, newContent: String) -> Bool {
        guard let idx = answers.firstIndex(where: { $0.id == answerId }) else { return false }
        answers[idx].content = newContent
        answers[idx].editedAt = Date()
        return true
    }

    @discardableResult
    public mutating func edit(title: String? = nil, body: String? = nil) -> Bool {
        var changed = false
        if let t = title, !t.isEmpty {
            self.title = t
            changed = true
        }
        if let b = body, !b.isEmpty {
            self.body = b
            changed = true
        }
        if changed { self.editedAt = Date() }
        return changed
    }

    public mutating func upvote() { votes += 1 }
    public mutating func downvote() { votes -= 1 }

    // MARK: - JSON helpers

    public func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    public static func fromJSON(_ data: Data) throws -> Question {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Question.self, from: data)
    }
}
