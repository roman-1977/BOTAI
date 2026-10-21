import Foundation

/// Provider-neutral, single-flight upload pipeline. Caller is responsible for authenticating
/// the account and selecting its isolated local database before invoking flush().
actor AttemptSyncCoordinator {
    private let backend: any BOTAIBackendAPI
    private let repository: LearningRepository

    init(backend: any BOTAIBackendAPI, repository: LearningRepository) {
        self.backend = backend
        self.repository = repository
    }

    /// A failure leaves every unacknowledged event pending. Empty/unmapped batches never hit the network.
    @discardableResult
    func flush() async throws -> Int {
        let request = try repository.mappedUploadBatch()
        guard !request.attempts.isEmpty else { return 0 }
        let response = try await backend.uploadAttempts(request)
        return try repository.acknowledgeUploadedAttempts(request: request, response: response)
    }
}
