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
