import Foundation

final class UserController {
    private let store: AccountStore

    init(store: AccountStore = DefaultAccountStore()) {
        self.store = store
    }

    // Create a new User (in-memory and persisted as Account). Returns the saved Account.
    func createUser(username: String, email: String, password: String, isAdmin: Bool = false) async throws -> User {
        let user = try User(username: username, email: email, password: password, isAdmin: isAdmin)
        // Upsert via AccountStore (stores account fields). If you need to persist user-specific fields,
        // extend your store / database schema accordingly.
        _ = try await store.upsert(user)
        return user
    }

    func loadUserByEmail(_ email: String) async throws -> User? {
        guard let acct = try await store.fetchByEmail(email) else { return nil }
        // Attempt to decode as User if stored representation included user fields;
        // otherwise create a lightweight User wrapper preserving account data.
        let user = User(id: acct.id,
                        username: acct.email.components(separatedBy: "@").first ?? acct.email,
                        email: acct.email,
                        passwordHash: acct.passwordHash,
                        salt: acct.salt,
                        verified: acct.verified,
                        isAdmin: acct.isAdmin,
                        sessionToken: acct.sessionToken)
        return user
    }

    func saveUser(_ user: User) async throws -> User {
        return try await store.upsert(user)
    }
}