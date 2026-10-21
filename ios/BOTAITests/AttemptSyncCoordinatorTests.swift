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

private actor SuspendedAttemptBackend: BOTAIBackendAPI {
    private var continuation: CheckedContinuation<Void, Never>?
    private var didStart = false
    func uploadAttempts(_ request: BOTAIUploadAttemptsRequest) async throws -> BOTAIUploadAttemptsResponse {
        didStart = true
        await withCheckedContinuation { continuation = $0 }
        return .init(schemaVersion: 1, acknowledgedIDs: request.attempts.map(\.id))
    }
    func started() -> Bool { didStart }
    func resume() { continuation?.resume(); continuation = nil }
}

private actor AccountGate {
    private var active = true
    func isActive() -> Bool { active }
    func deactivate() { active = false }
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

    @Test func accountChangesDuringNetworkRequestPreservesOutbox() async throws {
        let (learning, _) = try setup(mapped: true)
        let backend = SuspendedAttemptBackend()
        let gate = AccountGate()
        let sync = AttemptSyncCoordinator(backend: backend, repository: learning,
            isCurrentAccount: { await gate.isActive() })
        let operation = Task { try await sync.flush() }
        // Wait for the fake network call to enter its suspended state.
        for _ in 0..<1000 {
            if await backend.started() { break }
            await Task.yield()
        }
        #expect(await backend.started())
        await gate.deactivate()
        await backend.resume()
        #expect(try await operation.value == 0)
        #expect(try learning.outboxCount() == 1)
        #expect(try learning.load().0.count == 1)
    }

    @Test func concurrentFlushesDoNotUploadSameBatchTwice() async throws {
        let (learning, _) = try setup(mapped: true)
        let backend = SuspendedAttemptBackend()
        let sync = AttemptSyncCoordinator(backend: backend, repository: learning,
            isCurrentAccount: { true })
        let first = Task { try await sync.flush() }
        for _ in 0..<1000 {
            if await backend.started() { break }
            await Task.yield()
        }
        #expect(await backend.started())
        // First upload is suspended; the actor must not reenter the upload pipeline.
        #expect(try await sync.flush() == 0)
        #expect(try learning.outboxCount() == 1)
        await backend.resume()
        #expect(try await first.value == 1)
        #expect(try learning.outboxCount() == 0)
    }

    @Test func noAcknowledgementsPreserveQueue() async throws {
        let (learning, _) = try setup(mapped: true)
        let sync = AttemptSyncCoordinator(backend: FakeAttemptBackend(.acknowledgeNone), repository: learning, isCurrentAccount: { true })
        #expect(try await sync.flush() == 0)
        #expect(try learning.outboxCount() == 1)
    }
}
