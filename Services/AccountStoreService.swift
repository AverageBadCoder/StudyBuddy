import Foundation

protocol AccountStoreServicing {
    func upsert(_ account: Account) async throws -> Account
    func fetchByEmail(_ email: String) async throws -> Account?
    func fetchById(_ id: String) async throws -> Account?
    func deleteById(_ id: String) async throws -> Bool
}

/// Adapter around the SupabaseAccountStore stand-in.
struct AccountStoreService: AccountStoreServicing {
    func upsert(_ account: Account) async throws -> Account { try await SupabaseAccountStore.upsert(account) }
    func fetchByEmail(_ email: String) async throws -> Account? { try await SupabaseAccountStore.fetchByEmail(email) }
    func fetchById(_ id: String) async throws -> Account? {
        // reuse DefaultAccountStore implementation for id fetch
        return try await DefaultAccountStore().fetchById(id)
    }
    func deleteById(_ id: String) async throws -> Bool { try await SupabaseAccountStore.deleteById(id) }
}