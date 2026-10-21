import Foundation
import Testing
@testable import BOTAI

struct SyncSafetyTests {
    @Test func remoteRatingsPreserveAllThreeGrades() {
        #expect(SyncService.remoteResult(for: .again) == "incorrect")
        #expect(SyncService.remoteResult(for: .hard) == "hard")
        #expect(SyncService.remoteResult(for: .good) == "correct")
    }

    @Test func offlineOutboxRetainsUnmappedAttempts() throws {
        let db = try AppDatabase()
        let repository = LearningRepository(database: db)
        let attempt = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .hard)
        try repository.record(attempt, state: LearningState())
        #expect(try repository.outboxCount() == 1)
        #expect(try repository.pendingOutbox().first?.entityID == attempt.id.uuidString)
    }
}
