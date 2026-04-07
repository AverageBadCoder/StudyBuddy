import Foundation

final class FilePersistenceService {
    private let fm = FileManager.default
    private let base: URL

    init(folderName: String = "StudyBuddyData") {
        base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent(folderName, isDirectory: true)
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)
    }

    func save<T: Codable>(_ value: T, to filename: String) throws {
        let url = base.appendingPathComponent(filename)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(value)
        try data.write(to: url, options: .atomic)
    }

    func load<T: Codable>(_ filename: String, as type: T.Type) throws -> T {
        let url = base.appendingPathComponent(filename)
        let data = try Data(contentsOf: url)
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(T.self, from: data)
    }

    func exists(_ filename: String) -> Bool {
        fm.fileExists(atPath: base.appendingPathComponent(filename).path)
    }
}