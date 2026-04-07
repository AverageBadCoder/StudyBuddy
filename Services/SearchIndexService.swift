import Foundation

/// Simple in-memory index for Question title/body. Not persistent.
final class SearchIndexService {
    private var index: [String: Question] = [:] // id -> question

    func indexQuestion(_ q: Question) {
        index[q.id] = q
    }

    func removeQuestion(_ id: String) {
        index.removeValue(forKey: id)
    }

    func search(_ query: String, limit: Int = 50) -> [Question] {
        let q = query.lowercased()
        return index.values.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }.sorted { $0.createdAt > $1.createdAt }.prefix(limit).map { $0 }
    }
}