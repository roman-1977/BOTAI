import AuthenticationServices
import Observation
import Supabase

@MainActor @Observable
final class AuthStore {
    private(set) var isAuthenticated = false
    private(set) var errorMessage: String?
    private let client = SupabaseProvider.client

    func bootstrap() async { isAuthenticated = (try? await client.auth.session) != nil }
    func signInWithApple(idToken: String, nonce: String? = nil) async {
        do { _ = try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)); isAuthenticated = true; errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
    func signOut() async { try? await client.auth.signOut(); isAuthenticated = false }
}
