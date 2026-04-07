import Foundation

enum SupabaseError: Error {
    case badURL, httpError(Int, Data?)
    case decodingError(Error)
    case unknown
}

/// Thin wrapper for Supabase REST requests (PostgREST).
struct SupabaseService {
    static var baseURL: URL? { URL(string: SupabaseLib.urlString) }
    static var anonKey: String { SupabaseLib.anonKey }

    static func request(path: String,
                        method: String = "GET",
                        query: String? = nil,
                        body: Data? = nil,
                        additionalHeaders: [String: String] = [:]) async throws -> (Data, HTTPURLResponse) {
        guard var base = baseURL else { throw SupabaseError.badURL }
        var url = base.appendingPathComponent(path)
        if let q = query {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
            comps?.query = q
            if let u = comps?.url { url = u }
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        for (k, v) in additionalHeaders { req.setValue(v, forHTTPHeaderField: k) }
        if let b = body { req.httpBody = b }

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SupabaseError.unknown }
        guard (200...299).contains(http.statusCode) else { throw SupabaseError.httpError(http.statusCode, data) }
        return (data, http)
    }
}