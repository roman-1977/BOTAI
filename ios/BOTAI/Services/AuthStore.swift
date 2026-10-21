import AuthenticationServices
import Observation
import Supabase

@MainActor @Observable
final class AuthStore {
    private(set) var isAuthenticated = false
    private(set) var userID: UUID?
    private(set) var errorMessage: String?
    private let client = SupabaseProvider.client

    var localIdentity: LocalAccountStorage.Identity {
        userID.map { .authenticated($0) } ?? .guest
    }

    func bootstrap() async {
        didFailBootstrap = false
        do {
            let session = try await client.auth.session
            userID = session.user.id
            isAuthenticated = true
            errorMessage = nil
        } catch AuthError.sessionMissing {
            // Only a confirmed missing session is safe to treat as guest.
            userID = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            // Network, refresh and storage errors must not silently reveal guest content.
            errorMessage = error.localizedDescription
            isAuthenticated = false
            userID = nil
            didFailBootstrap = true
        }
    }

    private(set) var didFailBootstrap = false

    #if DEBUG
    func signInForDevelopment() async {
        do {
            let session = try await client.auth.signInAnonymously()
            userID = session.user.id
            isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif

    func signInWithApple(idToken: String, nonce: String? = nil) async {
        do {
            let session = try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
            userID = session.user.id
            isAuthenticated = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            userID = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
