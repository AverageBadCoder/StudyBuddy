import Foundation

final class ArchivePersistenceService {
    private let persistence = FilePersistenceService(folderName: "StudyBuddyArchives")

    func saveArchive(_ archive: Archive, filename: String) throws {
        try persistence.save(archive, to: filename)
    }

    func loadArchive(filename: String) throws -> Archive {
        try persistence.load(filename, as: Archive.self)
    }

    func exportArchiveData(_ archive: Archive) throws -> Data {
        try archive.toJSON()
    }

    func importArchiveData(_ data: Data) throws -> Archive {
        try Archive.fromJSON(data)
    }
}