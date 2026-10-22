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

    @Test func retryAfterTransientBackendFailureAcknowledgesOnce() async throws {
        let (learning, original) = try setup(mapped: true)
        let gate: @Sendable () async -> Bool = { true }
        let first = AttemptSyncCoordinator(backend: FakeAttemptBackend(.fail),
                                           repository: learning, isCurrentAccount: gate)
        await #expect(throws: BOTAIBackendError.missingServerQuestionMapping) {
            try await first.flush()
        }
        #expect(try learning.outboxCount() == 1)
        #expect(try learning.load().0.map(\.id) == [original.id])
        let backend = FakeAttemptBackend(.acknowledgeAll)
        let retry = AttemptSyncCoordinator(backend: backend, repository: learning,
                                           isCurrentAccount: gate)
        #expect(try await retry.flush() == 1)
        #expect(try learning.outboxCount() == 0)
        #expect(try learning.load().0.map(\.id) == [original.id])
        #expect(try await retry.flush() == 0)
        #expect(await backend.calls == 1)
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
        for _ in 0..<500 {
            if await backend.started() { break }
            try await Task.sleep(for: .milliseconds(2))
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
        for _ in 0..<500 {
            if await backend.started() { break }
            try await Task.sleep(for: .milliseconds(2))
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

private actor FakeSessionSummaryBackend: SessionSummaryBackendAPI {
    enum Behavior: Sendable { case acknowledgeAll, acknowledgeNone, foreignID, fail }
    let behavior: Behavior
    private(set) var calls = 0
    private(set) var received: [CompletedSessionSummary] = []
    init(_ behavior: Behavior) { self.behavior = behavior }
    func uploadSessionSummaries(_ summaries: [CompletedSessionSummary]) async throws -> [UUID] {
        calls += 1
        received = summaries
        switch behavior {
        case .acknowledgeAll: return summaries.map(\.sessionID)
        case .acknowledgeNone: return []
        case .foreignID: return [UUID()]
        case .fail: throw BOTAIBackendError.invalidAcknowledgement
        }
    }
}

private actor SuspendedSessionSummaryBackend: SessionSummaryBackendAPI {
    private var continuation: CheckedContinuation<Void, Never>?
    private var didStart = false
    func uploadSessionSummaries(_ summaries: [CompletedSessionSummary]) async throws -> [UUID] {
        didStart = true
        await withCheckedContinuation { continuation = $0 }
        return summaries.map(\.sessionID)
    }
    func started() -> Bool { didStart }
    func resume() { continuation?.resume(); continuation = nil }
}

struct SessionSummarySyncCoordinatorTests {
    private func setup() throws -> (LearningRepository, StudySession) {
        let repository = LearningRepository(database: try AppDatabase())
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 42, answered: 7, correct: 5)
        try repository.saveSession(session)
        return (repository, session)
    }

    @Test func offlineCompletionSurvivesDatabaseReopenAndUploadsExactlyOnce() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("botai-offline-summary-\(UUID().uuidString).sqlite").path
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: path + suffix)
            }
        }
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 81, answered: 2, correct: 1)
        do {
            let offline = LearningRepository(database: try AppDatabase(path: path))
            try offline.saveSession(session)
            #expect(try offline.pendingSessionSummaries().isEmpty)
            try offline.completeSession(session)
            try offline.completeSession(session)
            #expect(try offline.pendingSessionSummaries().map(\.sessionID) == [session.id])
        }
        let reopened = LearningRepository(database: try AppDatabase(path: path))
        #expect(try reopened.pendingSessionSummaries().map(\.sessionID) == [session.id])
        let offlineBackend = FakeSessionSummaryBackend(.fail)
        let offlineSync = SessionSummarySyncCoordinator(backend: offlineBackend,
            repository: reopened, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.invalidAcknowledgement) {
            try await offlineSync.flush()
        }
        #expect(try reopened.pendingSessionSummaries().count == 1)
        let onlineBackend = FakeSessionSummaryBackend(.acknowledgeAll)
        let onlineSync = SessionSummarySyncCoordinator(backend: onlineBackend,
            repository: reopened, isCurrentAccount: { true })
        #expect(try await onlineSync.flush() == 1)
        #expect(await onlineBackend.received == [CompletedSessionSummary(session: session)])
        #expect(try await onlineSync.flush() == 0)
        #expect(await onlineBackend.calls == 1)
        let restarted = LearningRepository(database: try AppDatabase(path: path))
        #expect(try restarted.pendingSessionSummaries().isEmpty)
        #expect(try restarted.sessions().count == 1)
    }

    @Test func unfinishedSessionIsNeverUploaded() async throws {
        let (repository, _) = try setup()
        let backend = FakeSessionSummaryBackend(.acknowledgeAll)
        let sync = SessionSummarySyncCoordinator(backend: backend, repository: repository,
            isCurrentAccount: { true })
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 0)
    }

    @Test func completedSessionUploadsOnlyAggregateAndAcknowledgesOnce() async throws {
        let (repository, session) = try setup()
        try repository.completeSession(session)
        let backend = FakeSessionSummaryBackend(.acknowledgeAll)
        let sync = SessionSummarySyncCoordinator(backend: backend, repository: repository,
            isCurrentAccount: { true })
        #expect(try await sync.flush() == 1)
        #expect(try repository.pendingSessionSummaries().isEmpty)
        #expect(await backend.received == [CompletedSessionSummary(session: session)])
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 1)
        #expect(try repository.sessions().count == 1)
    }

    @Test func failuresAndMissingAckKeepSummaryPending() async throws {
        let (repository, session) = try setup()
        try repository.completeSession(session)
        let failed = SessionSummarySyncCoordinator(backend: FakeSessionSummaryBackend(.fail),
            repository: repository, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.invalidAcknowledgement) { try await failed.flush() }
        let unconfirmed = SessionSummarySyncCoordinator(backend: FakeSessionSummaryBackend(.acknowledgeNone),
            repository: repository, isCurrentAccount: { true })
        #expect(try await unconfirmed.flush() == 0)
        #expect(try repository.pendingSessionSummaries().count == 1)
        let retry = SessionSummarySyncCoordinator(backend: FakeSessionSummaryBackend(.acknowledgeAll),
            repository: repository, isCurrentAccount: { true })
        #expect(try await retry.flush() == 1)
        #expect(try repository.pendingSessionSummaries().isEmpty)
    }

    @Test func foreignAcknowledgementRejected() async throws {
        let (repository, session) = try setup()
        try repository.completeSession(session)
        let sync = SessionSummarySyncCoordinator(backend: FakeSessionSummaryBackend(.foreignID),
            repository: repository, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.invalidAcknowledgement) { try await sync.flush() }
        #expect(try repository.pendingSessionSummaries().count == 1)
    }

    @Test func inactiveAccountPreventsUpload() async throws {
        let (repository, session) = try setup()
        try repository.completeSession(session)
        let backend = FakeSessionSummaryBackend(.acknowledgeAll)
        let sync = SessionSummarySyncCoordinator(backend: backend, repository: repository,
            isCurrentAccount: { false })
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 0)
        #expect(try repository.pendingSessionSummaries().count == 1)
    }

    @Test func accountSwitchDuringNetworkPreservesQueue() async throws {
        let (repository, session) = try setup()
        try repository.completeSession(session)
        let backend = SuspendedSessionSummaryBackend()
        let gate = AccountGate()
        let sync = SessionSummarySyncCoordinator(backend: backend, repository: repository,
            isCurrentAccount: { await gate.isActive() })
        let task = Task { try await sync.flush() }
        for _ in 0..<500 {
            if await backend.started() { break }
            try await Task.sleep(for: .milliseconds(2))
        }
        #expect(await backend.started())
        await gate.deactivate()
        await backend.resume()
        #expect(try await task.value == 0)
        #expect(try repository.pendingSessionSummaries().count == 1)
    }

    @Test func overlappingFlushDoesNotDoubleUpload() async throws {
        let (repository, session) = try setup()
        try repository.completeSession(session)
        let backend = SuspendedSessionSummaryBackend()
        let sync = SessionSummarySyncCoordinator(backend: backend, repository: repository,
            isCurrentAccount: { true })
        let task = Task { try await sync.flush() }
        for _ in 0..<500 {
            if await backend.started() { break }
            try await Task.sleep(for: .milliseconds(2))
        }
        #expect(await backend.started())
        #expect(try await sync.flush() == 0)
        await backend.resume()
        #expect(try await task.value == 1)
        #expect(try repository.pendingSessionSummaries().isEmpty)
    }
}

private actor FakeTopicAggregateBackend: TopicAggregateBackendAPI {
    enum Behavior: Sendable { case all, none, foreign, failure }
    let behavior: Behavior
    private(set) var calls = 0
    init(_ behavior: Behavior) { self.behavior = behavior }
    func uploadTopicAggregates(_ summaries: [CompletedSessionSummary]) async throws -> [UUID] {
        calls += 1
        switch behavior {
        case .all: return summaries.map(\.sessionID)
        case .none: return []
        case .foreign: return [UUID()]
        case .failure: throw BOTAIBackendError.invalidAcknowledgement
        }
    }
}

struct TopicAggregateSyncCoordinatorTests {
    private func setup() throws -> (LearningRepository, UUID) {
        let repository = LearningRepository(database: try AppDatabase())
        let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var topics = SessionTopicAccumulator()
        topics.record(correct: true, attribution: attribution)
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 12, answered: 1, correct: 1)
        try repository.completeSession(session, topics: topics)
        return (repository, session.id)
    }

    @Test func offlineTopicQueueSurvivesReopenAndWaitsForParentAck() async throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("botai-offline-topics-\(UUID().uuidString).sqlite").path
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: path + suffix)
            }
        }
        let sessionID = UUID()
        do {
            let offline = LearningRepository(database: try AppDatabase(path: path))
            let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
            var topics = SessionTopicAccumulator()
            topics.record(correct: true, attribution: attribution)
            let session = StudySession(id: sessionID, startedAt: .now, endedAt: .now,
                activeSeconds: 25, answered: 1, correct: 1)
            try offline.completeSession(session, topics: topics)
            #expect(try offline.pendingTopicSessionSummaries().isEmpty)
        }
        let reopened = LearningRepository(database: try AppDatabase(path: path))
        let backend = FakeTopicAggregateBackend(.all)
        let sync = TopicAggregateSyncCoordinator(backend: backend, repository: reopened,
            isCurrentAccount: { true })
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 0)
        try reopened.acknowledgeSessionSummaries([sessionID])
        #expect(try reopened.pendingTopicSessionSummaries().count == 1)
        #expect(try await sync.flush() == 1)
        #expect(try await sync.flush() == 0)
        #expect(await backend.calls == 1)
        let restarted = LearningRepository(database: try AppDatabase(path: path))
        #expect(try restarted.pendingSessionSummaries().isEmpty)
        #expect(try restarted.pendingTopicSessionSummaries().isEmpty)
    }

    @Test func waitsUntilParentSummaryAcknowledged() async throws {
        let (repository, _) = try setup()
        let backend = FakeTopicAggregateBackend(.all)
        let coordinator = TopicAggregateSyncCoordinator(backend: backend,
            repository: repository, isCurrentAccount: { true })
        #expect(try await coordinator.flush() == 0)
        #expect(await backend.calls == 0)
    }

    @Test func successfulTopicUploadIsAcknowledgedExactlyOnce() async throws {
        let (repository, id) = try setup()
        try repository.acknowledgeSessionSummaries([id])
        let backend = FakeTopicAggregateBackend(.all)
        let coordinator = TopicAggregateSyncCoordinator(backend: backend,
            repository: repository, isCurrentAccount: { true })
        #expect(try await coordinator.flush() == 1)
        #expect(try await coordinator.flush() == 0)
        #expect(await backend.calls == 1)
        #expect(try repository.pendingTopicSessionSummaries().isEmpty)
    }

    @Test func absentAckPreservesQueueForRetry() async throws {
        let (repository, id) = try setup()
        try repository.acknowledgeSessionSummaries([id])
        let coordinator = TopicAggregateSyncCoordinator(backend: FakeTopicAggregateBackend(.none),
            repository: repository, isCurrentAccount: { true })
        #expect(try await coordinator.flush() == 0)
        #expect(try repository.pendingTopicSessionSummaries().count == 1)
        let retry = TopicAggregateSyncCoordinator(backend: FakeTopicAggregateBackend(.all),
            repository: repository, isCurrentAccount: { true })
        #expect(try await retry.flush() == 1)
    }

    @Test func foreignAckIsRejected() async throws {
        let (repository, id) = try setup()
        try repository.acknowledgeSessionSummaries([id])
        let coordinator = TopicAggregateSyncCoordinator(backend: FakeTopicAggregateBackend(.foreign),
            repository: repository, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.invalidAcknowledgement) {
            try await coordinator.flush()
        }
        #expect(try repository.pendingTopicSessionSummaries().count == 1)
    }

    @Test func inactiveAccountNeverUploads() async throws {
        let (repository, id) = try setup()
        try repository.acknowledgeSessionSummaries([id])
        let backend = FakeTopicAggregateBackend(.all)
        let coordinator = TopicAggregateSyncCoordinator(backend: backend,
            repository: repository, isCurrentAccount: { false })
        #expect(try await coordinator.flush() == 0)
        #expect(await backend.calls == 0)
    }
}

private actor SuspendedTopicAggregateBackend: TopicAggregateBackendAPI {
    private var continuation: CheckedContinuation<Void, Never>?
    private var didStart = false
    private(set) var calls = 0
    func uploadTopicAggregates(_ summaries: [CompletedSessionSummary]) async throws -> [UUID] {
        calls += 1
        didStart = true
        await withCheckedContinuation { continuation = $0 }
        return summaries.map(\.sessionID)
    }
    func started() -> Bool { didStart }
    func resume() { continuation?.resume(); continuation = nil }
}

struct TopicAggregateConcurrencyTests {
    private func setup() throws -> (LearningRepository, UUID) {
        let repository = LearningRepository(database: try AppDatabase())
        let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var topics = SessionTopicAccumulator()
        topics.record(correct: true, attribution: attribution)
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
            activeSeconds: 9, answered: 1, correct: 1)
        try repository.completeSession(session, topics: topics)
        try repository.acknowledgeSessionSummaries([session.id])
        return (repository, session.id)
    }

    @Test func accountSwitchDuringTopicUploadLeavesPendingQueue() async throws {
        let (repository, _) = try setup()
        let backend = SuspendedTopicAggregateBackend()
        let gate = AccountGate()
        let coordinator = TopicAggregateSyncCoordinator(backend: backend,
            repository: repository, isCurrentAccount: { await gate.isActive() })
        let task = Task { try await coordinator.flush() }
        for _ in 0..<500 {
            if await backend.started() { break }
            try await Task.sleep(for: .milliseconds(2))
        }
        #expect(await backend.started())
        await gate.deactivate()
        await backend.resume()
        #expect(try await task.value == 0)
        #expect(try repository.pendingTopicSessionSummaries().count == 1)
    }

    @Test func concurrentTopicFlushesOnlySendOnce() async throws {
        let (repository, _) = try setup()
        let backend = SuspendedTopicAggregateBackend()
        let coordinator = TopicAggregateSyncCoordinator(backend: backend,
            repository: repository, isCurrentAccount: { true })
        let task = Task { try await coordinator.flush() }
        for _ in 0..<500 {
            if await backend.started() { break }
            try await Task.sleep(for: .milliseconds(2))
        }
        #expect(await backend.started())
        #expect(try await coordinator.flush() == 0)
        await backend.resume()
        #expect(try await task.value == 1)
        #expect(await backend.calls == 1)
        #expect(try repository.pendingTopicSessionSummaries().isEmpty)
    }

    @Test func networkFailurePreservesTopicQueue() async throws {
        let (repository, _) = try setup()
        let coordinator = TopicAggregateSyncCoordinator(backend: FakeTopicAggregateBackend(.failure),
            repository: repository, isCurrentAccount: { true })
        await #expect(throws: BOTAIBackendError.invalidAcknowledgement) {
            try await coordinator.flush()
        }
        #expect(try repository.pendingTopicSessionSummaries().count == 1)
    }
}
