import Foundation
import Testing
@testable import BOTAI

struct LocalAccountStorageTests {
    @Test func keychainBindingPersistsReplacesAndClearsWithoutTouchingRealAccount() {
        let service = "BOTAI.offline-account-binding.tests." + UUID().uuidString
        defer { OfflineAccountBinding.clear(service: service) }
        #expect(OfflineAccountBinding.read(service: service) == nil)
        let first = UUID(), second = UUID()
        let firstStatus = OfflineAccountBinding.save(first, service: service)
        if firstStatus == -34018 {
            // Unsigned simulator tests have no Keychain entitlement; verify on a signed build.
            print("KEYCHAIN_INTEGRATION_NOT_VERIFIED: missing entitlement (-34018)")
            return
        }
        #expect(firstStatus == 0, "Keychain insert OSStatus: \(firstStatus)")
        #expect(OfflineAccountBinding.read(service: service) == first)
        OfflineAccountBinding.save(second, service: service)
        #expect(OfflineAccountBinding.read(service: service) == second)
        OfflineAccountBinding.clear(service: service)
        #expect(OfflineAccountBinding.read(service: service) == nil)
    }

    @Test @MainActor func offlineIdentityAndReconnectPolicyMatrix() {
        let first = UUID(), second = UUID()
        let network = URLError(.notConnectedToInternet)
        #expect(AuthStore.offlineIdentity(after: network, cachedAccount: first, persistedSessionAccount: first) == first)
        #expect(AuthStore.offlineIdentity(after: network, cachedAccount: nil, persistedSessionAccount: first) == nil)
        #expect(AuthStore.offlineIdentity(after: network, cachedAccount: first, persistedSessionAccount: nil) == nil)
        #expect(AuthStore.offlineIdentity(after: network, cachedAccount: first, persistedSessionAccount: second) == nil)
        #expect(AuthStore.offlineIdentity(after: URLError(.serverCertificateUntrusted), cachedAccount: first, persistedSessionAccount: first) == nil)
        #expect(AuthStore.offlineIdentity(after: URLError(.userAuthenticationRequired), cachedAccount: first, persistedSessionAccount: first) == nil)
        #expect(AuthStore.offlineIdentity(after: NSError(domain: "storage", code: 1), cachedAccount: first, persistedSessionAccount: first) == nil)
        #expect(AuthStore.canRestoreSync(localAccount: first, verifiedAccount: first))
        #expect(!AuthStore.canRestoreSync(localAccount: first, verifiedAccount: second))
        #expect(!AuthStore.canRestoreSync(localAccount: nil, verifiedAccount: first))
    }

    @Test func staleSyncServiceCannotUploadAfterAccountSwitchOrSignOut() {
        let first = UUID(), second = UUID()
        #expect(SyncService.canUpload(boundAccountID: first, authenticatedAccountID: first))
        #expect(!SyncService.canUpload(boundAccountID: first, authenticatedAccountID: second))
        #expect(!SyncService.canUpload(boundAccountID: first, authenticatedAccountID: nil))
    }

    @Test @MainActor func reconnectFailuresLockOfflineStudyExceptTransportOutage() {
        #expect(!AuthStore.mustLockOfflineStudy(after: URLError(.notConnectedToInternet)))
        #expect(!AuthStore.mustLockOfflineStudy(after: URLError(.timedOut)))
        #expect(AuthStore.mustLockOfflineStudy(after: URLError(.serverCertificateUntrusted)))
        #expect(AuthStore.mustLockOfflineStudy(after: URLError(.userAuthenticationRequired)))
        #expect(AuthStore.mustLockOfflineStudy(after: NSError(domain: "auth", code: 401)))
        #expect(AuthStore.mustLockOfflineStudy(after: NSError(domain: "backend", code: 503)))
    }

    @Test @MainActor func offlineFallbackOnlyAcceptsTransportFailures() {
        #expect(AuthStore.isTransportFailure(URLError(.notConnectedToInternet)))
        #expect(AuthStore.isTransportFailure(URLError(.timedOut)))
        #expect(!AuthStore.isTransportFailure(URLError(.serverCertificateUntrusted)))
        #expect(!AuthStore.isTransportFailure(URLError(.userAuthenticationRequired)))
        #expect(!AuthStore.isTransportFailure(URLError(.badURL)))
        #expect(!AuthStore.isTransportFailure(NSError(domain: "authentication", code: 401)))
        #expect(!AuthStore.isTransportFailure(NSError(domain: "storage", code: 1)))
    }

    @Test func guestAndTwoAccountsPersistSeparateLearningDatabases() throws {
        let fm = FileManager.default
        let support = fm.temporaryDirectory.appendingPathComponent("botai-account-isolation-" + UUID().uuidString)
        defer { try? fm.removeItem(at: support) }
        let guest = LocalAccountStorage.Identity.guest
        let first = LocalAccountStorage.Identity.authenticated(UUID())
        let second = LocalAccountStorage.Identity.authenticated(UUID())
        let identities = [guest, first, second]
        for (index, identity) in identities.enumerated() {
            let folder = LocalAccountStorage.directory(for: identity, support: support)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            let db = try AppDatabase(path: folder.appendingPathComponent("learning.sqlite").path)
            let repository = LearningRepository(database: db)
            #expect(try repository.outboxCount() == 0)
            for _ in 0...index {
                let attempt = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .good)
                try repository.record(attempt, state: LearningState())
            }
            #expect(try repository.outboxCount() == index + 1)
        }
        for (index, identity) in identities.enumerated() {
            let path = LocalAccountStorage.directory(for: identity, support: support).appendingPathComponent("learning.sqlite").path
            let reopened = LearningRepository(database: try AppDatabase(path: path))
            #expect(try reopened.outboxCount() == index + 1)
        }
    }

    @Test func pendingSessionAggregatesNeverCrossAccountDatabaseBoundaries() throws {
        let fm = FileManager.default
        let support = fm.temporaryDirectory.appendingPathComponent("botai-summary-isolation-" + UUID().uuidString)
        defer { try? fm.removeItem(at: support) }
        let first = LocalAccountStorage.Identity.authenticated(UUID())
        let second = LocalAccountStorage.Identity.authenticated(UUID())
        let firstFolder = LocalAccountStorage.directory(for: first, support: support)
        let secondFolder = LocalAccountStorage.directory(for: second, support: support)
        try fm.createDirectory(at: firstFolder, withIntermediateDirectories: true)
        try fm.createDirectory(at: secondFolder, withIntermediateDirectories: true)
        let firstRepository = LearningRepository(database: try AppDatabase(path: firstFolder.appendingPathComponent("learning.sqlite").path))
        let secondRepository = LearningRepository(database: try AppDatabase(path: secondFolder.appendingPathComponent("learning.sqlite").path))
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now, activeSeconds: 1, answered: 1, correct: 1)
        try firstRepository.completeSession(session)
        #expect(try firstRepository.pendingSessionSummaries().map(\.sessionID) == [session.id])
        #expect(try secondRepository.pendingSessionSummaries().isEmpty)
        #expect(try secondRepository.pendingTopicSessionSummaries().isEmpty)
        let reopenedFirst = LearningRepository(database: try AppDatabase(path: firstFolder.appendingPathComponent("learning.sqlite").path))
        #expect(try reopenedFirst.pendingSessionSummaries().map(\.sessionID) == [session.id])
    }

    @Test func databaseOpenFailureDoesNotReplaceExistingNonDatabaseFile() throws {
        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent("botai-corrupt-db-" + UUID().uuidString)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: folder) }
        let path = folder.appendingPathComponent("learning.sqlite")
        let original = Data("not a SQLite database".utf8)
        try original.write(to: path)
        #expect(throws: Error.self) { try AppDatabase(path: path.path) }
        #expect(try Data(contentsOf: path) == original)
    }

    @Test func databaseOpenFailureDoesNotCreateMissingParentDirectory() throws {
        let fm = FileManager.default
        let folder = fm.temporaryDirectory.appendingPathComponent("botai-missing-parent-" + UUID().uuidString)
        defer { try? fm.removeItem(at: folder) }
        let path = folder.appendingPathComponent("nested/learning.sqlite")
        #expect(throws: Error.self) { try AppDatabase(path: path.path) }
        #expect(!fm.fileExists(atPath: folder.path))
    }

    @Test func namespacesAreDistinctAndDeterministic() {
        let first = UUID(), second = UUID()
        let guest = LocalAccountStorage.directoryName(for: .guest)
        let account = LocalAccountStorage.directoryName(for: .authenticated(first))
        #expect(guest == "BOTAI")
        #expect(LocalAccountStorage.directoryName(for: .guest, uiTesting: true) == "BOTAI-UITests")
        #expect(guest != account)
        #expect(account != LocalAccountStorage.directoryName(for: .authenticated(second)))
        #expect(account == LocalAccountStorage.directoryName(for: .authenticated(first)))
        #expect(account.hasPrefix("BOTAI-user-"))
        #expect(LocalAccountStorage.directoryName(for: .guest, uiTesting: true) != guest)
    }

    @Test func migrationNeverOverwritesAndNeverDeletesLegacyData() throws {
        let fm = FileManager.default
        let support = fm.temporaryDirectory.appendingPathComponent("botai-storage-test-" + UUID().uuidString)
        defer { try? fm.removeItem(at: support) }
        let legacy = support.appendingPathComponent("BOTAI")
        try fm.createDirectory(at: legacy, withIntermediateDirectories: true)
        let source = legacy.appendingPathComponent("learning.sqlite")
        try Data("legacy".utf8).write(to: source)
        let id = LocalAccountStorage.Identity.authenticated(UUID())
        #expect(try LocalAccountStorage.copyCheckpointedLegacyDatabase(from: legacy, to: id, support: support))
        let destination = LocalAccountStorage.directory(for: id, support: support).appendingPathComponent("learning.sqlite")
        #expect(try Data(contentsOf: destination) == Data("legacy".utf8))
        #expect(try !LocalAccountStorage.copyCheckpointedLegacyDatabase(from: legacy, to: id, support: support))
        #expect(try Data(contentsOf: source) == Data("legacy".utf8))
        try Data("new".utf8).write(to: destination)
        #expect(try !LocalAccountStorage.copyCheckpointedLegacyDatabase(from: legacy, to: id, support: support))
        #expect(try Data(contentsOf: destination) == Data("new".utf8))
    }

    @Test func migrationRefusesGuestDestinationAndSharedMemorySidecar() throws {
        let fm = FileManager.default
        let support = fm.temporaryDirectory.appendingPathComponent("botai-shm-test-" + UUID().uuidString)
        defer { try? fm.removeItem(at: support) }
        let legacy = support.appendingPathComponent("BOTAI")
        try fm.createDirectory(at: legacy, withIntermediateDirectories: true)
        let source = legacy.appendingPathComponent("learning.sqlite")
        try Data("db".utf8).write(to: source)
        #expect(try !LocalAccountStorage.copyCheckpointedLegacyDatabase(from: legacy, to: .guest, support: support))
        try Data("shared".utf8).write(to: legacy.appendingPathComponent("learning.sqlite-shm"))
        let account = LocalAccountStorage.Identity.authenticated(UUID())
        #expect(try !LocalAccountStorage.copyCheckpointedLegacyDatabase(from: legacy, to: account, support: support))
        #expect(!fm.fileExists(atPath: LocalAccountStorage.directory(for: account, support: support).appendingPathComponent("learning.sqlite").path))
        #expect(try Data(contentsOf: source) == Data("db".utf8))
    }

    @Test func migrationRefusesUncheckpointedWalDatabase() throws {
        let fm = FileManager.default
        let support = fm.temporaryDirectory.appendingPathComponent("botai-wal-test-" + UUID().uuidString)
        defer { try? fm.removeItem(at: support) }
        let legacy = support.appendingPathComponent("BOTAI")
        try fm.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data("db".utf8).write(to: legacy.appendingPathComponent("learning.sqlite"))
        try Data("pending".utf8).write(to: legacy.appendingPathComponent("learning.sqlite-wal"))
        let id = LocalAccountStorage.Identity.authenticated(UUID())
        #expect(try !LocalAccountStorage.copyCheckpointedLegacyDatabase(from: legacy, to: id, support: support))
        #expect(!fm.fileExists(atPath: LocalAccountStorage.directory(for: id, support: support).appendingPathComponent("learning.sqlite").path))
    }
}
