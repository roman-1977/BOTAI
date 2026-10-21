import Foundation
import Testing
@testable import BOTAI

struct RemoteQuestionMappingTests {
    @Test func mappingDoesNotAlterExistingLearningAttempts() throws {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let local = UUID()
        let attempt = Attempt(id: UUID(), questionID: local, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState(intervalDays: 1, streak: 1, nextDueAt: .now))
        let mapping = RemoteQuestionMappingRepository(database: database)
        try mapping.saveVerified(localQuestionID: local, remoteQuestionID: UUID(), remoteVersionID: UUID())
        let restored = try learning.load()
        #expect(restored.0.count == 1)
        #expect(restored.0.first?.id == attempt.id)
        #expect(restored.0.first?.questionID == attempt.questionID)
        #expect(restored.0.first?.rating == attempt.rating)
        #expect(abs((restored.0.first?.occurredAt.timeIntervalSince1970 ?? 0) - attempt.occurredAt.timeIntervalSince1970) < 1)
        #expect(try learning.outboxCount() == 1)
    }

    @Test func mappingPersistsAcrossDatabaseReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("learning.sqlite").path
        let local = UUID(), remote = UUID(), version = UUID()
        do {
            let repository = RemoteQuestionMappingRepository(database: try AppDatabase(path: path))
            #expect(try repository.mapping(for: local) == nil)
            try repository.saveVerified(localQuestionID: local, remoteQuestionID: remote, remoteVersionID: version)
        }
        let reopened = RemoteQuestionMappingRepository(database: try AppDatabase(path: path))
        let mapping = try #require(try reopened.mapping(for: local))
        #expect(mapping.remoteQuestionID == remote.uuidString)
        #expect(mapping.remoteQuestionVersionID == version.uuidString)
        #expect(try reopened.mapping(for: UUID()) == nil)
    }
}
