import Foundation
import Supabase

/// Server uploads require an authoritative question and question-version mapping.
/// Until that mapping exists, local attempts remain durable in the outbox.
actor SyncService {
    private let client: SupabaseClient
    private let repository: LearningRepository
    private let mappings: RemoteQuestionMappingRepository
    private var flushInFlight = false

    init(client: SupabaseClient = SupabaseProvider.client, repository: LearningRepository,
         mappings: RemoteQuestionMappingRepository) {
        self.client = client
        self.repository = repository
        self.mappings = mappings
    }

    func flush(questions: [StudyQuestion]) async {
        // A new coordinator is created per call; guard at the service boundary too.
        guard !flushInFlight else { return }
        flushInFlight = true
        defer { flushInFlight = false }
        // Capture the actual authenticated Supabase identity, not a caller-supplied UUID.
        guard let originalUserID = try? await client.auth.session.user.id else { return }
        let accountCheck: @Sendable () async -> Bool = { [client] in
            guard let currentID = try? await client.auth.session.user.id else { return false }
            return currentID == originalUserID
        }
        // Only publish questions with durable pending attempts and known local content.
        if let pending = try? repository.pendingOutbox() {
            let ids = Set(pending.filter { $0.entityType == "attempt" }.compactMap {
                try? repository.attempt(id: $0.entityID)?.questionID
            })
            let publisher = RemoteQuestionPublisher(client: client, mappings: mappings,
                                                    isCurrentAccount: accountCheck)
            // Historical attempts publish from their immutable answer-time snapshot.
            // Use the attempt UUID as the mapping key to avoid mutating the current card.
            if let snapshots = try? repository.unpublishedSnapshots() {
                for snapshot in snapshots {
                    guard await accountCheck() else { return }
                    if (try? mappings.mapping(for: snapshot.attemptID)) == nil {
                        _ = try? await publisher.publish(snapshot.question)
                    }
                    if let mapping = try? mappings.mapping(for: snapshot.attemptID),
                       let remoteID = UUID(uuidString: mapping.remoteQuestionID),
                       let versionID = UUID(uuidString: mapping.remoteQuestionVersionID),
                       await accountCheck() {
                        try? repository.pinPublishedSnapshot(attemptID: snapshot.attemptID,
                            remoteQuestionID: remoteID, versionID: versionID)
                    }
                }
            }
            for question in questions where ids.contains(question.id.uuidString) {
                guard await accountCheck() else { return }
                if (try? mappings.mapping(for: question.id)) == nil {
                    _ = try? await publisher.publish(question)
                }
            }
        }
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
