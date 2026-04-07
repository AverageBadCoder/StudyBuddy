import Foundation

protocol AccountStore {
    func upsert(_ account: Account) async throws -> Account
    func fetchByEmail(_ email: String) async throws -> Account?
    func fetchById(_ id: String) async throws -> Account?
    func deleteById(_ id: String) async throws -> Bool
}

struct DefaultAccountStore: AccountStore {
    func upsert(_ account: Account) async throws -> Account {
        try await SupabaseAccountStore.upsert(account)
    }

    func fetchByEmail(_ email: String) async throws -> Account? {
        try await SupabaseAccountStore.fetchByEmail(email)
    }

    func fetchById(_ id: String) async throws -> Account? {
        // SupabaseAccountStore doesn't have fetchById in the stand-in; implement via query
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? id
        guard let base = URL(string: SupabaseLib.urlString) else { throw URLError(.badURL) }
        var url = base.appendingPathComponent("rest/v1/accounts")
        url.append("?\(String(format: "id=eq.%@", encoded))")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(SupabaseLib.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(SupabaseLib.anonKey, forHTTPHeaderField: "apikey")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "DefaultAccountStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Supabase fetch error"])
        }
        let decoder = JSONDecoder()
        let rows = try decoder.decode([SupabaseAccountStore.AccountDTO].self, from: data)
        guard let dto = rows.first else { return nil }
        return dto.toAccount()
    }

    func deleteById(_ id: String) async throws -> Bool {
        try await SupabaseAccountStore.deleteById(id)
    }
}