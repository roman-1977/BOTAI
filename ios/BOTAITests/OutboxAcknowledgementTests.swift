import Foundation
import Testing
@testable import BOTAI

struct OutboxAcknowledgementTests {
    @Test func onlyAcknowledgedAttemptsLeaveOutbox() throws {
        let db = try AppDatabase()
        let repository = LearningRepository(database: db)
        let a = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .good)
        let b = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .hard)
        try repository.record(a, state: LearningState())
        try repository.record(b, state: LearningState())
        let request = BOTAIUploadAttemptsRequest(attempts: [a, b].map {
            BOTAIUploadAttempt(id: $0.id, questionID: $0.questionID, questionVersionID: UUID(), occurredAt: $0.occurredAt, result: "correct")
        })
        #expect(try repository.outboxCount() == 2)
        #expect(try repository.acknowledgeUploadedAttempts(request: request, response: .init(schemaVersion: 1, acknowledgedIDs: [a.id])) == 1)
        #expect(try repository.outboxCount() == 1)
        #expect(try repository.pendingOutbox().first?.entityID == b.id.uuidString)
        #expect(try repository.load().0.count == 2)
        #expect(throws: BOTAIBackendError.invalidAcknowledgement) {
            try repository.acknowledgeUploadedAttempts(request: request, response: .init(schemaVersion: 1, acknowledgedIDs: [UUID()]))
        }
        #expect(try repository.outboxCount() == 1)
        #expect(try repository.acknowledgeUploadedAttempts(request: request, response: .init(schemaVersion: 1, acknowledgedIDs: [b.id])) == 1)
        #expect(try repository.outboxCount() == 0)
        #expect(try repository.load().0.count == 2)
    }
}
