import Foundation
import Supabase

/// Uploads only aggregate statistics of completed sessions.
/// Legacy per-answer outbox remains on disk but is deliberately never transmitted.
actor SyncService {
    private let client: SupabaseClient
    private let repository: LearningRepository
    private let boundAccountID: UUID
    private var flushInFlight = false
    private var pendingFlush = false

    init(client: SupabaseClient = SupabaseProvider.client, repository: LearningRepository,
         mappings: RemoteQuestionMappingRepository, boundAccountID: UUID) {
        self.client = client
        self.repository = repository
        self.boundAccountID = boundAccountID
        // Keep the initializer compatible while the legacy mapping storage is retained.
        _ = mappings
    }

    func flush(questions: [StudyQuestion]) async {
        // Retain caller compatibility. No question content or identifiers go to the server.
        _ = questions
        if flushInFlight {
            pendingFlush = true
            return
        }
        flushInFlight = true
        repeat {
            pendingFlush = false
            await performFlush()
        } while pendingFlush
        flushInFlight = false
    }

    /// An actor retained by an in-flight task may outlive a sign-out or account switch.
    /// Never let its old local repository upload under a newly authenticated user.
    static func canUpload(boundAccountID: UUID, authenticatedAccountID: UUID?) -> Bool {
        boundAccountID == authenticatedAccountID
    }

    private func performFlush() async {
        guard let originalUserID = try? await client.auth.session.user.id,
              Self.canUpload(boundAccountID: boundAccountID, authenticatedAccountID: originalUserID) else { return }
        let accountCheck: @Sendable () async -> Bool = { [client, boundAccountID] in
            guard let currentID = try? await client.auth.session.user.id else { return false }
            return currentID == originalUserID && currentID == boundAccountID
        }
        let coordinator = SessionSummarySyncCoordinator(
            backend: SupabaseBackendAPI(client: client), repository: repository,
            isCurrentAccount: accountCheck)
        _ = try? await coordinator.flush()
        let topicCoordinator = TopicAggregateSyncCoordinator(
            backend: SupabaseBackendAPI(client: client), repository: repository,
            isCurrentAccount: accountCheck)
        _ = try? await topicCoordinator.flush()
    }
    /// Legacy local outbox serialization only; no attempt uploads are scheduled.
    static func remoteResult(for rating: RecallRating) -> String {
        switch rating {
        case .again: "incorrect"
        case .hard: "hard"
        case .good: "correct"
        }
    }

}
