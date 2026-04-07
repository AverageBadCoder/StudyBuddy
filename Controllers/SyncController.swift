import Foundation

final class SyncController {
    private let accountStore: AccountStore

    init(accountStore: AccountStore = DefaultAccountStore()) {
        self.accountStore = accountStore
    }

    // Sync a local account/user to remote store
    func syncAccount(_ account: Account) async throws -> Account {
        try await accountStore.upsert(account)
    }

    // Fetch remote account and return it
    func fetchAccountByEmail(_ email: String) async throws -> Account? {
        try await accountStore.fetchByEmail(email)
    }

    // Delete remote account
    func deleteAccount(_ id: String) async throws -> Bool {
        try await accountStore.deleteById(id)
    }
}