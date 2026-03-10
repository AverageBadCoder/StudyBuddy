import Foundation
import CryptoKit
import Security

enum AccountError: Error {
    case invalidCredentials
    case weakPassword
}

/// Working Account model with hashed password (SHA256 + salt),
/// secure random 16-character id, simple login/logout and password change.
final class Account: Codable {
    var id: String
    var email: String
    private(set) var passwordHash: String
    private var salt: String
    var verified: Bool
    var isAdmin: Bool
    /// Optional session token set on successful login
    private(set) var sessionToken: String?

    init(email: String, password: String, isAdmin: Bool = false) throws {
        guard Account.isStrongPassword(password) else {
            throw AccountError.weakPassword
        }
        self.id = Account.randomId()
        self.email = email
        self.salt = Account.randomId(length: 8)
        self.passwordHash = Account.hash(password: password, salt: self.salt)
        self.verified = false
        self.isAdmin = isAdmin
    }

    // MARK: - Authentication

    /// Attempt to login; returns true on success and sets a session token.
    func login(email: String, password: String) -> Bool {
        guard email == self.email, verifyPassword(password) else {
            return false
        }
        self.sessionToken = UUID().uuidString
        return true
    }

    func logout() {
        self.sessionToken = nil
    }

    private func verifyPassword(_ password: String) -> Bool {
        return Account.hash(password: password, salt: salt) == passwordHash
    }

    /// Change password after validating the old one. Throws on invalid or weak new password.
    func changePassword(oldPassword: String, newPassword: String) throws {
        guard verifyPassword(oldPassword) else { throw AccountError.invalidCredentials }
        guard Account.isStrongPassword(newPassword) else { throw AccountError.weakPassword }
        // rotate salt when changing password
        self.salt = Account.randomId(length: 8)
        self.passwordHash = Account.hash(password: newPassword, salt: salt)
    }

    // MARK: - Verification helpers

    /// Simple heuristic to verify college ownership:
    /// marks verified true if email ends with .edu or contains the provided college string.
    @discardableResult
    func verifyCollege(college: String) -> Bool {
        let c = college.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if c.isEmpty {
            self.verified = false
            return false
        }
        let emailLower = email.lowercased()
        if emailLower.hasSuffix(".edu") || emailLower.contains(c) {
            self.verified = true
        } else {
            self.verified = false
        }
        return self.verified
    }

    func changeAdminStatus() {
        self.isAdmin.toggle()
    }

    // MARK: - Utilities (hashing / random id / password rules)

    /// Generate a random string of given length (default 16) using
    /// letters and digits. Uses SecRandomCopyBytes for cryptographic randomness.
    static func randomId(length: Int = 16) -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        var result = ""
        result.reserveCapacity(length)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
        if status == errSecSuccess {
            for b in randomBytes {
                result.append(charset[Int(b) % charset.count])
            }
        } else {
            // fallback to UUID-derived string if secure RNG fails
            let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            let chars = Array(uuid)
            for i in 0..<length {
                result.append(chars[i % chars.count])
            }
        }
        return result
    }

    private static func hash(password: String, salt: String) -> String {
        let combined = password + ":" + salt
        let data = Data(combined.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func isStrongPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
}

// Usage examples (for testing):
// do {
//     let acct = try Account(email: "student@university.edu", password: "s3curePass")
//     let ok = acct.login(email: "student@university.edu", password: "s3curePass")
//     print("login ok:", ok, "session:", acct.sessionToken ?? "nil")
//     acct.verifyCollege(college: "university")
// } catch {
//     print("account error:", error)
//