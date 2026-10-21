import Foundation
import Testing
@testable import BOTAI

private actor FakeAttemptBackend: BOTAIBackendAPI {
    enum Behavior: Sendable { case acknowledgeAll, acknowledgeNone, foreignID, fail }
    let behavior: Behavior
    private(set) var calls = 0
    init(_ behavior: Behavior) { self.behavior = behavior }
    func uploadAttempts(_ request: BOTAIUploadAttemptsRequest) async throws -> BOTAIUploadAttemptsResponse {
        calls += 1
        switch behavior {
        case .acknowledgeAll: return .init(schemaVersion: 1, acknowledgedIDs: request.attempts.map(\.id))
        case .acknowledgeNone: return .init(schemaVersion: 1, acknowledgedIDs: [])
        case .foreignID: return .init(schemaVersion: 1, acknowledgedIDs: [UUID()])
        case .fail: throw BOTAIBackendError.missingServerQuestionMapping
        }
    }
}

struct AttemptSyncCoordinatorTests {
    private func setup(mapped: Bool) throws -> (LearningRepository, Attempt) {
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let attempt = Attempt(id: UUID(), questionID: UUID(), occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState())
        if mapped {
            try RemoteQuestionMappingRepository(database: database).saveVerified(
                localQuestionID: attempt.questionID, remoteQuestionID: UUID(), remoteVersionID: UUID())
        }
        return (learning, attempt)
    }

    @Test func unmappedDataNeverReachesBackend() async throws {
        let (learning, _) = try setup(mapped: false)
        let backend = FakeAttemptBackend(.acknowledgeAll)
        let sync = AttemptSyncCoordinator(backend: backend, repository: learning, isCurrentAccount: { true })
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 0)
        #expect(try learning.outboxCount() == 1)
    }

    @Test func confirmedUploadRemovesOutboxButNotHistory() async throws {
        let (learning, _) = try setup(mapped: true)
        let backend = FakeAttemptBackend(.acknowledgeAll)
        let sync = AttemptSyncCoordinator(backend: backend, repository: learning, isCurrentAccount: { true })
        #expect(try await sync.flush() == 1)
        #expect(try learning.outboxCount() == 0)
        #expect(try learning.load().0.count == 1)
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 1)
    }

    @Test func rejectedAcknowledgementPreservesQueue() async throws {
        let (learning, _) = try setup(mapped: true)
        let sync = AttemptSyncCoordinator(backend: FakeAttemptBackend(.foreignID), repository: learning, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.invalidAcknowledgement) { try await sync.flush() }
        #expect(try learning.outboxCount() == 1)
    }

    @Test func backendFailurePreservesQueue() async throws {
        let (learning, _) = try setup(mapped: true)
        let sync = AttemptSyncCoordinator(backend: FakeAttemptBackend(.fail), repository: learning, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.missingServerQuestionMapping) { try await sync.flush() }
        #expect(try learning.outboxCount() == 1)
    }

    @Test func changedAccountBeforeUploadPreventsNetworkAndDeletion() async throws {
        let (learning, _) = try setup(mapped: true)
        let backend = FakeAttemptBackend(.acknowledgeAll)
        let sync = AttemptSyncCoordinator(backend: backend, repository: learning, isCurrentAccount: { false })
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 0)
        #expect(try learning.outboxCount() == 1)
    }

    @Test func noAcknowledgementsPreserveQueue() async throws {
        let (learning, _) = try setup(mapped: true)
        let sync = AttemptSyncCoordinator(backend: FakeAttemptBackend(.acknowledgeNone), repository: learning, isCurrentAccount: { true })
        #expect(try await sync.flush() == 0)
        #expect(try learning.outboxCount() == 1)
    }
}
