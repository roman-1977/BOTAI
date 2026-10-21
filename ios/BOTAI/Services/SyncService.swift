import Foundation
import Supabase

/// Server uploads require an authoritative question and question-version mapping.
/// Until that mapping exists, local attempts remain durable in the outbox.
actor SyncService {
    private let client: SupabaseClient
    private let repository: LearningRepository
    private var flushInFlight = false

    init(client: SupabaseClient = SupabaseProvider.client, repository: LearningRepository) {
        self.client = client
        self.repository = repository
    }

    func flush() async {
        // A new coordinator is created per call; guard at the service boundary too.
        guard !flushInFlight else { return }
        flushInFlight = true
        defer { flushInFlight = false }
        // Capture the actual authenticated Supabase identity, not a caller-supplied UUID.
        guard let originalUserID = try? await client.auth.session.user.id else { return }
        let backend = SupabaseBackendAPI(client: client)
        let coordinator = AttemptSyncCoordinator(backend: backend, repository: repository,
            isCurrentAccount: { [client] in
                guard let currentID = try? await client.auth.session.user.id else { return false }
                return currentID == originalUserID
            })
        _ = try? await coordinator.flush()
    }

    static func remoteResult(for rating: RecallRating) -> String {
        switch rating {
        case .again: "incorrect"
        case .hard: "hard"
        case .good: "correct"
        }
    }
}
