import Foundation

final class AccountController {
    private let store: AccountStore

    init(store: AccountStore = DefaultAccountStore()) {
        self.store = store
    }

    // Sign up: create local Account and persist
    func signUp(email: String, password: String, isAdmin: Bool = false) async throws -> Account {
        let account = try Account(email: email, password: password, isAdmin: isAdmin)
        return try await store.upsert(account)
    }

    // Sign in: fetch account and verify password using Account.login(instance method).
    func signIn(email: String, password: String) async throws -> Account {
        guard let acct = try await store.fetchByEmail(email) else {
            throw AccountError.invalidCredentials
        }
        let ok = acct.login(email: email, password: password)
        guard ok else { throw AccountError.invalidCredentials }
        // persist session token if login set it
        return try await store.upsert(acct)
    }

    // Sign out: clear session token and persist
    func signOut(accountId: String) async throws {
        guard let acct = try await store.fetchById(accountId) else { return }
        acct.logout()
        _ = try await store.upsert(acct)
    }

    // Change password: validates and persists
    func changePassword(accountId: String, oldPassword: String, newPassword: String) async throws {
        guard let acct = try await store.fetchById(accountId) else { throw AccountError.invalidCredentials }
        try acct.changePassword(oldPassword: oldPassword, newPassword: newPassword)
        _ = try await store.upsert(acct)
    }

    // Verify college heuristic and persist
    @discardableResult
    func verifyCollege(accountId: String, college: String) async throws -> Bool {
        guard let acct = try await store.fetchById(accountId) else { return false }
        let ok = acct.verifyCollege(college: college)
        if ok { _ = try await store.upsert(acct) }
        return ok
    }
}