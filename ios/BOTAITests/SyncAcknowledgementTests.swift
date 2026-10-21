import Foundation
import Testing
@testable import BOTAI

struct SyncAcknowledgementTests {
    private func request() -> BOTAIUploadAttemptsRequest {
        BOTAIUploadAttemptsRequest(attempts: [
            BOTAIUploadAttempt(id: UUID(), questionID: UUID(), questionVersionID: UUID(), occurredAt: .now, result: "correct"),
            BOTAIUploadAttempt(id: UUID(), questionID: UUID(), questionVersionID: UUID(), occurredAt: .now, result: "hard")
        ])
    }

    @Test func partialAcknowledgementsOnlyConfirmReturnedIDs() throws {
        let batch = request()
        let id = batch.attempts[0].id
        let result = try SyncAcknowledgement.verifiedIDs(request: batch, response: .init(schemaVersion: 1, acknowledgedIDs: [id]))
        #expect(result == Set([id]))
    }

    @Test func foreignAcknowledgementIsRejected() throws {
        let batch = request()
        #expect(throws: BOTAIBackendError.invalidAcknowledgement) {
            try SyncAcknowledgement.verifiedIDs(request: batch, response: .init(schemaVersion: 1, acknowledgedIDs: [UUID()]))
        }
    }

    @Test func duplicateAcknowledgementIsRejected() throws {
        let batch = request()
        let id = batch.attempts[0].id
        #expect(throws: BOTAIBackendError.invalidAcknowledgement) {
            try SyncAcknowledgement.verifiedIDs(request: batch, response: .init(schemaVersion: 1, acknowledgedIDs: [id, id]))
        }
    }

    @Test func incompatibleVersionIsRejected() throws {
        let batch = request()
        #expect(throws: BOTAIBackendError.incompatibleSchemaVersion) {
            try SyncAcknowledgement.verifiedIDs(request: batch, response: .init(schemaVersion: 2, acknowledgedIDs: []))
        }
    }
}
