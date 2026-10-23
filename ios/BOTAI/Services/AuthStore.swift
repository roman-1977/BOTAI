import AuthenticationServices
import Observation
import Supabase
import Security

/// Device-local account binding; never store a token or use the guest namespace as a fallback.
enum OfflineAccountBinding {
    private static let defaultService = "BOTAI.offline-account-binding"
    private static let account = "last-verified-user"

    static func read(service: String = defaultService) -> UUID? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let raw = String(data: data, encoding: .utf8) else { return nil }
        return UUID(uuidString: raw)
    }

    @discardableResult
    static func save(_ id: UUID, service: String = defaultService) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let data = Data(id.uuidString.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertion = query
            attributes.forEach { insertion[$0.key] = $0.value }
            return SecItemAdd(insertion as CFDictionary, nil)
        }
        return status
    }

    static func clear(service: String = defaultService) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        _ = SecItemDelete(query as CFDictionary)
    }
}

@MainActor @Observable
final class AuthStore {
    private(set) var isAuthenticated = false
    private(set) var userID: UUID?
    private(set) var errorMessage: String?
    private(set) var isBootstrapping = false
    private let client = SupabaseProvider.client
    private(set) var isOfflineLocalSession = false

    /// Only transport failures permit offline access; invalid or revoked auth never does.
    static func isTransportFailure(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            let offlineCodes: Set<Int> = [-1009, -1005, -1001, -1004, -1003, -1006, -1018, -1020]
            return offlineCodes.contains(nsError.code)
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return isTransportFailure(underlying)
        }
        return false
    }

    /// Pure policy shared by cold-launch and reconnection: an account mismatch
    /// must never attach a sync client to a different local database.
    static func canRestoreSync(localAccount: UUID?, verifiedAccount: UUID) -> Bool {
        localAccount == verifiedAccount
    }

    static func offlineIdentity(after error: Error, cachedAccount: UUID?, persistedSessionAccount: UUID?) -> UUID? {
        guard isTransportFailure(error), let cachedAccount,
              cachedAccount == persistedSessionAccount else { return nil }
        return cachedAccount
    }

    var localIdentity: LocalAccountStorage.Identity {
        userID.map { .authenticated($0) } ?? .guest
    }

    static func isConfirmedMissingSession(_ error: Error) -> Bool {
        guard let authError = error as? AuthError else { return false }
        return authError == .sessionMissing
    }

    func bootstrap() async {
        isBootstrapping = true
        defer { isBootstrapping = false }
        didFailBootstrap = false
        isOfflineLocalSession = false
        do {
            let session = try await client.auth.session
            userID = session.user.id
            isAuthenticated = true
            errorMessage = nil
            OfflineAccountBinding.save(session.user.id)
        } catch {
            isAuthenticated = false
            if let cached = Self.offlineIdentity(
                after: error,
                cachedAccount: OfflineAccountBinding.read(),
                persistedSessionAccount: client.auth.currentSession?.user.id
            ) {
                // Local access to the exact previously verified account only. Never sync offline.
                userID = cached
                isOfflineLocalSession = true
                errorMessage = nil
            } else {
                userID = nil
                if Self.isConfirmedMissingSession(error) {
                    OfflineAccountBinding.clear()
                    errorMessage = nil
                } else {
                    errorMessage = error.localizedDescription
                    didFailBootstrap = true
                }
            }
        }
    }

    /// A transport outage preserves local access; all other failures lock it.
    static func mustLockOfflineStudy(after error: Error) -> Bool {
        !isTransportFailure(error)
    }

    /// Revalidate without hiding local study UI while the network is still unavailable.
    func reconnectOfflineSession() async -> Bool {
        guard isOfflineLocalSession else { return isAuthenticated }
        do {
            let session = try await client.auth.session
            guard Self.canRestoreSync(localAccount: userID, verifiedAccount: session.user.id) else {
                // Never silently switch the current offline study session to another account.
                isOfflineLocalSession = false
                userID = nil
                didFailBootstrap = true
                errorMessage = "Учётная запись изменилась. Повторите авторизацию."
                return false
            }
            isAuthenticated = true
            isOfflineLocalSession = false
            OfflineAccountBinding.save(session.user.id)
            errorMessage = nil
            return true
        } catch {
            if Self.mustLockOfflineStudy(after: error) {
                // Fail closed on auth rejection, TLS failures, or unexpected server errors.
                // A retry may revalidate the account; never keep local study unlocked.
                isOfflineLocalSession = false
                userID = nil
                didFailBootstrap = true
                errorMessage = "Не удалось подтвердить учётную запись."
            }
            return false
        }
    }

    private(set) var didFailBootstrap = false

    #if DEBUG
    func signInForDevelopment() async {
        do {
            let session = try await client.auth.signInAnonymously()
            userID = session.user.id
            isAuthenticated = true
            isOfflineLocalSession = false
            OfflineAccountBinding.save(session.user.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif

    func setAppleSignInError(_ message: String) { errorMessage = message }

    private(set) var registrationNeedsEmailConfirmation = false

    func signInWithEmail(_ email: String, password: String) async {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            userID = session.user.id
            isAuthenticated = true
            isOfflineLocalSession = false
            OfflineAccountBinding.save(session.user.id)
            registrationNeedsEmailConfirmation = false
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func registerWithEmail(_ email: String, password: String) async {
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            if let session = response.session {
                userID = session.user.id
                isAuthenticated = true
                isOfflineLocalSession = false
                OfflineAccountBinding.save(session.user.id)
                registrationNeedsEmailConfirmation = false
            } else {
                // Email confirmation is required by the backend. Never unlock
                // a local account before an authenticated session exists.
                registrationNeedsEmailConfirmation = true
            }
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func requestPasswordReset(_ email: String) async {
        do {
            try await client.auth.resetPasswordForEmail(email)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    func signInWithApple(idToken: String, nonce: String? = nil) async {
        do {
            let session = try await client.auth.signInWithIdToken(credentials: .init(provider: .apple, idToken: idToken, nonce: nonce))
            userID = session.user.id
            isAuthenticated = true
            isOfflineLocalSession = false
            OfflineAccountBinding.save(session.user.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        // Supabase clears its persisted session before calling the remote logout endpoint.
        // Even when that request fails offline, local study access must end immediately.
        defer {
            OfflineAccountBinding.clear()
            userID = nil
            isAuthenticated = false
            isOfflineLocalSession = false
        }
        do {
            try await client.auth.signOut()
            errorMessage = nil
        } catch {
            // Remote token revocation may be pending, but local sign-out is unconditional.
            errorMessage = "Выход на устройстве выполнен. Не удалось завершить серверную сессию."
        }
    }
}
