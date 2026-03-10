import Foundation
import Supabase

// Lightweight convenience wrapper around the Supabase Swift client.
// Set SUPABASE_URL and SUPABASE_ANON_KEY in your environment (or replace the defaults below).
public enum SupabaseLib {
    public static let urlString: String = {
        ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? "https://fipoeezmmdwtejwirrhp.supabase.co"
    }()

    public static let anonKey: String = {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpcG9lZXptbWR3dGVqd2lycmhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1MTc1NzksImV4cCI6MjA4NzA5MzU3OX0.pzswMc2d76CNQz_UBPMS_cO5Jo_WBiNyz9J607h_1vY"
    }()

    public static let client: SupabaseClient = {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid SUPABASE_URL: \(urlString)")
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }()

    // Simple helper — adjust / expand these helpers to match your app needs and the exact supabase-swift API version.
    public static func signUp(email: String, password: String) async throws {
        _ = try await client.auth.signUp(email: email, password: password)
    }

    public static func signIn(email: String, password: String) async throws {
        _ = try await client.auth.signIn(email: email, password: password)
    }

    public static func signOut() async throws {
        try await client.auth.signOut()
    }
}