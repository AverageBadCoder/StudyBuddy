import Foundation

protocol AuthServicing {
    func signUp(email: String, password: String) async throws -> Account
    func signIn(email: String, password: String) async throws -> Account
    func signOut(accountId: String) async throws
}

/// Lightweight Auth service that uses AccountStore and Keychain for session persistence.
final class AuthService: AuthServicing {
    private let accountStore: AccountStore
    private let sessionKeyPrefix = "studybuddy_session_"

    init(accountStore: AccountStore = DefaultAccountStore()) {
        self.accountStore = accountStore
    }

    func signUp(email: String, password: String) async throws -> Account {
        let acct = try Account(email: email, password: password)
        let saved = try await accountStore.upsert(acct)
        return saved
    }

    func signIn(email: String, password: String) async throws -> Account {
        guard let acct = try await accountStore.fetchByEmail(email) else { throw AccountError.invalidCredentials }
        let ok = acct.login(email: email, password: password)
        guard ok else { throw AccountError.invalidCredentials }
        _ = try await accountStore.upsert(acct)
        if let token = acct.sessionToken {
            KeychainService.set(token, forKey: sessionKeyPrefix + acct.id)
        }
        return acct
    }

    func signOut(accountId: String) async throws {
        guard let acct = try await accountStore.fetchById(accountId) else { return }
        acct.logout()
        _ = try await accountStore.upsert(acct)
        KeychainService.delete(sessionKeyPrefix + accountId)
    }

    func sessionToken(for accountId: String) -> String? {
        KeychainService.get(sessionKeyPrefix + accountId)
    }
}