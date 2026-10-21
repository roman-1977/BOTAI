import Foundation
import Testing
@testable import BOTAI

struct MappedUploadBatchTests {
    @Test func onlyVerifiedMappingsAreIncludedAndOthersRemainPending() throws {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let mappings = RemoteQuestionMappingRepository(database: database)
        let mapped = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .hard)
        let unmapped = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .good)
        try learning.record(mapped, state: LearningState())
        try learning.record(unmapped, state: LearningState())
        #expect(try learning.mappedUploadBatch().attempts.isEmpty)
        let remote = UUID(), version = UUID()
        try mappings.saveVerified(localQuestionID: mapped.questionID, remoteQuestionID: remote, remoteVersionID: version)
        let batch = try learning.mappedUploadBatch()
        #expect(batch.attempts.count == 1)
        #expect(batch.attempts.first?.id == mapped.id)
        #expect(batch.attempts.first?.questionID == remote)
        #expect(batch.attempts.first?.questionVersionID == version)
        #expect(batch.attempts.first?.result == "hard")
        #expect(try learning.outboxCount() == 2)
        #expect(try learning.acknowledgeUploadedAttempts(request: batch, response: .init(schemaVersion: 1, acknowledgedIDs: [mapped.id])) == 1)
        #expect(try learning.outboxCount() == 1)
        #expect(try learning.pendingOutbox().first?.entityID == unmapped.id.uuidString)
    }
}
