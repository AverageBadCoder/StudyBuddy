import Foundation

final class QuestionService {
    private let tokenService: TokenServicing
    private let persistence: FilePersistenceService

    init(tokenService: TokenServicing = TokenService(),
         persistence: FilePersistenceService = FilePersistenceService()) {
        self.tokenService = tokenService
        self.persistence = persistence
    }

    /// Create question, deduct a token if provided.
    func createQuestion(author: User, course: Course, title: String, body: String, using token: Token? = nil) throws -> Question {
        if let t = token {
            guard tokenService.tryUseToken(t) else { throw NSError(domain: "QuestionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Insufficient tokens"]) }
        }
        return course.createQuestion(authorId: author.id, title: title, body: body)
    }

    func editQuestion(course: Course, questionId: String, editor: User, newTitle: String?, newBody: String?) -> Bool {
        guard let q = course.findQuestion(byId: questionId), (q.authorId == editor.id || editor.isAdmin) else { return false }
        return course.editQuestion(id: questionId, newTitle: newTitle, newBody: newBody)
    }

    func deleteQuestion(course: Course, questionId: String, requester: User, archiveIt: Bool = true) -> Bool {
        guard let q = course.findQuestion(byId: questionId), (q.authorId == requester.id || requester.isAdmin) else { return false }
        return course.removeQuestion(byId: questionId, archiveIt: archiveIt, archivedBy: requester.id)
    }

    // Simple local export for a question
    func exportQuestion(_ q: Question, filename: String) throws {
        try persistence.save(q, to: filename)
    }

    func importQuestion(filename: String) throws -> Question {
        try persistence.load(filename, as: Question.self)
    }
}