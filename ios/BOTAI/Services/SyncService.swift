import Foundation
import Supabase

/// Server uploads require an authoritative question and question-version mapping.
/// Until that mapping exists, local attempts remain durable in the outbox.
actor SyncService {
    private let client: SupabaseClient
    private let repository: LearningRepository

    init(client: SupabaseClient = SupabaseProvider.client, repository: LearningRepository) {
        self.client = client
        self.repository = repository
    }

    func flush() async {
        guard (try? await client.auth.session.user) != nil else { return }
        // Do not acknowledge, fabricate foreign keys for, or transmit local-only attempts.
        // The future sync implementation must resolve server QuestionVersion IDs first.
        _ = try? repository.pendingOutbox()
    }

    static func remoteResult(for rating: RecallRating) -> String {
        switch rating {
        case .again: "incorrect"
        case .hard: "hard"
        case .good: "correct"
        }
    }
}
