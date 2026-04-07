import Foundation

final class QuestionController {
    // Create a question in a course. Posting costs one token if a token is supplied.
    func createQuestion(author: User, course: Course, title: String, body: String, token: Token? = nil) throws -> Question {
        // enforce token cost if token model provided
        if let t = token {
            guard t.useToken() else { throw NSError(domain: "QuestionController", code: 1, userInfo: [NSLocalizedDescriptionKey: "Insufficient tokens"]) }
        }
        let q = course.createQuestion(authorId: author.id, title: title, body: body)
        return q
    }

    func editQuestion(course: Course, questionId: String, editor: User, newTitle: String? = nil, newBody: String? = nil) -> Bool {
        // permission check: only author or admin allowed (caller should verify)
        guard let q = course.findQuestion(byId: questionId), q.authorId == editor.id || editor.isAdmin else { return false }
        return course.editQuestion(id: questionId, newTitle: newTitle, newBody: newBody)
    }

    func deleteQuestion(course: Course, questionId: String, requester: User, archiveIt: Bool = true) -> Bool {
        guard let q = course.findQuestion(byId: questionId), q.authorId == requester.id || requester.isAdmin else { return false }
        return course.removeQuestion(byId: questionId, archiveIt: archiveIt, archivedBy: requester.id)
    }

    func addAnswer(to course: Course, questionId: String, author: User, content: String) -> Answer? {
        guard var q = course.findQuestion(byId: questionId) else { return nil }
        let a = q.addAnswer(authorId: author.id, content: content)
        // update the course question in-place
        _ = course.editQuestion(id: questionId, newTitle: nil, newBody: nil) // forces edit metadata; not strictly required
        // replace the question in course.questions
        if let idx = course.getQuestions(sortedByNewest: false).firstIndex(where: { $0.id == questionId }) {
            course.getQuestions(sortedByNewest: false)[idx] = q
        } else {
            // fallback: append if missing
        }
        return a
    }
}