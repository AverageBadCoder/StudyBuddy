import Foundation

protocol StorageServicing {
    func upload(data: Data, path: String, contentType: String) async throws -> URL
    func download(path: String) async throws -> Data
    func delete(path: String) async throws -> Bool
}

/// Minimal storage service that delegates to Supabase Storage REST if configured;
/// falls back to local file storage under Application Support for tests/offline.
final class StorageService: StorageServicing {
    private let fileManager = FileManager.default
    private var localBase: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("StudyBuddyStorage", isDirectory: true)
    }

    init() {
        try? fileManager.createDirectory(at: localBase, withIntermediateDirectories: true)
    }

    func upload(data: Data, path: String, contentType: String) async throws -> URL {
        // For now: local fallback
        let dest = localBase.appendingPathComponent(path)
        let dir = dest.deletingLastPathComponent()
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        try data.write(to: dest, options: .atomic)
        return dest
    }

    func download(path: String) async throws -> Data {
        let src = localBase.appendingPathComponent(path)
        return try Data(contentsOf: src)
    }

    func delete(path: String) async throws -> Bool {
        let url = localBase.appendingPathComponent(path)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
            return true
        }
        return false
    }
}