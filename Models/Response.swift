import Foundation

/// Convenience extensions for the Answer model (defined in Models/Question.swift).
/// Adds editing, voting and simple JSON / time helpers so users can respond to questions.
public extension Answer {
    /// Mutating edit of the answer content (sets editedAt).
    mutating func edit(_ newContent: String) {
        self.content = newContent
        self.editedAt = Date()
    }

    /// Non-mutating copy with edited content.
    func edited(_ newContent: String) -> Answer {
        var copy = self
        copy.content = newContent
        copy.editedAt = Date()
        return copy
    }

    /// Vote helpers.
    mutating func upvote() { votes += 1 }
    mutating func downvote() { votes -= 1 }

    /// Time since posted in seconds.
    var timeSincePostSeconds: Int {
        Int(Date().timeIntervalSince(self.createdAt))
    }

    /// Simple JSON helpers (ISO8601 dates).
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func fromJSON(_ data: Data) throws -> Answer {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Answer.self, from: data)
    }
}
