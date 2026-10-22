import Foundation

/// Provider-neutral, single-flight upload pipeline. Caller is responsible for authenticating
/// the account and selecting its isolated local database before invoking flush().
actor AttemptSyncCoordinator {
    private let backend: any BOTAIBackendAPI
    private let repository: LearningRepository
    private let isCurrentAccount: @Sendable () async -> Bool
    private var uploadInFlight = false

    /// The account guard must compare against the identity captured when this coordinator was created.
    /// No permissive default: production callers must explicitly bind account ownership.
    init(backend: any BOTAIBackendAPI, repository: LearningRepository,
         isCurrentAccount: @escaping @Sendable () async -> Bool) {
        self.backend = backend
        self.repository = repository
        self.isCurrentAccount = isCurrentAccount
    }

    /// A failure leaves every unacknowledged event pending. Empty/unmapped batches never hit the network.
    @discardableResult
    func flush() async throws -> Int {
        // Actors are reentrant at suspension points: prevent overlapping uploads.
        guard !uploadInFlight else { return 0 }
        uploadInFlight = true
        defer { uploadInFlight = false }
        guard await isCurrentAccount() else { return 0 }
        let request = try repository.mappedUploadBatch()
        guard !request.attempts.isEmpty else { return 0 }
        guard await isCurrentAccount() else { return 0 }
        let response = try await backend.uploadAttempts(request)
        // Auth may change during network suspension. Never apply stale acknowledgements.
        guard await isCurrentAccount() else { return 0 }
        return try repository.acknowledgeUploadedAttempts(request: request, response: response)
    }
}
import Foundation

/// Auth-scoped, retryable upload of immutable completed-session aggregates.
actor SessionSummarySyncCoordinator {
    private let backend: any SessionSummaryBackendAPI
    private let repository: LearningRepository
    private let isCurrentAccount: @Sendable () async -> Bool
    private var inFlight = false

    init(backend: any SessionSummaryBackendAPI, repository: LearningRepository,
         isCurrentAccount: @escaping @Sendable () async -> Bool) {
        self.backend = backend
        self.repository = repository
        self.isCurrentAccount = isCurrentAccount
    }

    @discardableResult
    func flush() async throws -> Int {
        guard !inFlight else { return 0 }
        inFlight = true
        defer { inFlight = false }
        guard await isCurrentAccount() else { return 0 }
        let pending = try repository.pendingSessionSummaries()
        guard !pending.isEmpty, await isCurrentAccount() else { return 0 }
        let acknowledged = try await backend.uploadSessionSummaries(pending)
        guard await isCurrentAccount() else { return 0 }
        let pendingIDs = Set(pending.map(\.sessionID))
        guard Set(acknowledged).isSubset(of: pendingIDs) else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        try repository.acknowledgeSessionSummaries(acknowledged)
        return acknowledged.count
    }
}

/// Runs after parent session upload; topic ACK is independently durable.
actor TopicAggregateSyncCoordinator {
    private let backend: any TopicAggregateBackendAPI
    private let repository: LearningRepository
    private let isCurrentAccount: @Sendable () async -> Bool
    private var inFlight = false

    init(backend: any TopicAggregateBackendAPI, repository: LearningRepository,
         isCurrentAccount: @escaping @Sendable () async -> Bool) {
        self.backend = backend
        self.repository = repository
        self.isCurrentAccount = isCurrentAccount
    }

    @discardableResult
    func flush() async throws -> Int {
        guard !inFlight else { return 0 }
        inFlight = true
        defer { inFlight = false }
        guard await isCurrentAccount() else { return 0 }
        let pending = try repository.pendingTopicSessionSummaries()
        guard !pending.isEmpty, await isCurrentAccount() else { return 0 }
        let acknowledged = try await backend.uploadTopicAggregates(pending)
        guard await isCurrentAccount() else { return 0 }
        guard Set(acknowledged).isSubset(of: Set(pending.map(\.sessionID))) else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        try repository.acknowledgeTopicSessionSummaries(acknowledged)
        return acknowledged.count
    }
}
