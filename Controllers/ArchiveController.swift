import Foundation

final class ArchiveController {
    func archiveQuestion(course: Course, questionId: String, by userId: String? = nil) -> Bool {
        course.archiveQuestion(byId: questionId, archivedBy: userId)
    }

    func pruneArchive(course: Course, olderThanDays days: Int) {
        course.updateArchive(pruneOlderThanDays: days)
    }

    func exportArchive(course: Course) throws -> Data {
        try course.archive.toJSON()
    }

    func importArchive(course: Course, data: Data) throws {
        let imported = try Archive.fromJSON(data)
        // merge imported storedQuestions (avoid duplicates)
        imported.storedQuestions.forEach { archived in
            course.archive.archive(archived.original, by: archived.archivedBy)
        }
    }
}