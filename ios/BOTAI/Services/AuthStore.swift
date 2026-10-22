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
            if Self.isTransportFailure(error), let cached = OfflineAccountBinding.read() {
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
        do {
            try await client.auth.signOut()
            OfflineAccountBinding.clear()
            userID = nil
            isAuthenticated = false
            isOfflineLocalSession = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
