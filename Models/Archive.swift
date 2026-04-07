import Foundation

/// Archive model for storing old questions (keeps full Question snapshot and metadata).
/// Uses Question from Models/User.swift.
struct ArchivedQuestion: Codable, Identifiable, Equatable {
    let id: String
    let archivedAt: Date
    let original: Question
    let archivedBy: String? // optional user id who archived

    init(original: Question, archivedBy: String? = nil) {
        self.id = original.id
        self.archivedAt = Date()
        self.original = original
        self.archivedBy = archivedBy
    }
}

class Archive: Codable {
    let id: String
    var courseID: String
    private(set) var storedQuestions: [ArchivedQuestion]

    init(id: String = UUID().uuidString, courseID: String, storedQuestions: [ArchivedQuestion] = []) {
        self.id = id
        self.courseID = courseID
        self.storedQuestions = storedQuestions
    }

    /// Archive a Question (stores a snapshot).
    func archive(_ question: Question, by userId: String? = nil) {
        // avoid duplicates: remove existing with same id then append new snapshot
        storedQuestions.removeAll { $0.id == question.id }
        storedQuestions.append(ArchivedQuestion(original: question, archivedBy: userId))
    }

    /// Remove an archived question by id. Returns true if removed.
    @discardableResult
    func remove(questionId: String) -> Bool {
        if let idx = storedQuestions.firstIndex(where: { $0.id == questionId }) {
            storedQuestions.remove(at: idx)
            return true
        }
        return false
    }

    /// Find an archived question by id.
    func find(questionId: String) -> ArchivedQuestion? {
        return storedQuestions.first(where: { $0.id == questionId })
    }

    /// Prune archived questions older than given number of days.
    func prune(olderThanDays days: Int) {
        guard days > 0 else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        storedQuestions.removeAll { $0.archivedAt < cutoff }
    }

    /// Return archived questions sorted by archivedAt (newest first).
    func allSortedNewestFirst() -> [ArchivedQuestion] {
        return storedQuestions.sorted { $0.archivedAt > $1.archivedAt }
    }

    // Simple persistence helpers (JSON)
    func toJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func fromJSON(_ data: Data) throws -> Archive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Archive.self, from: data)
    }
}