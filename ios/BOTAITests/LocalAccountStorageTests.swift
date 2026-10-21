import Foundation
import Testing
@testable import BOTAI

struct LocalAccountStorageTests {
    @Test func namespacesAreDistinctAndDeterministic() {
        let first = UUID(), second = UUID()
        let guest = LocalAccountStorage.directoryName(for: .guest)
        let account = LocalAccountStorage.directoryName(for: .authenticated(first))
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
