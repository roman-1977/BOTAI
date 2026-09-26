import Foundation
import Supabase

struct AttemptUpload: Encodable {
    let id: String
    let user_id: String
    let question_id: String
    let question_version_id: String
    let result: String
    let answered_at: Date
}

actor SyncService {
    private let client: SupabaseClient
    private let repository: LearningRepository
    init(client: SupabaseClient = SupabaseProvider.client, repository: LearningRepository) { self.client = client; self.repository = repository }

    func flush() async {
        guard let user = try? await client.auth.session.user else { return }
        guard let items = try? repository.pendingOutbox() else { return }
        for item in items where item.nextRetryAt.map({ $0 <= .now }) ?? true {
            do {
                guard item.entityType == "attempt", let attempt = try repository.attempt(id: item.entityID) else { try repository.acknowledgeOutbox(id: item.id); continue }
                // Demo content uses stable IDs as both question and version IDs until downloaded server content replaces it.
                let payload = AttemptUpload(id: attempt.id, user_id: user.id.uuidString, question_id: attempt.questionID, question_version_id: attempt.questionID, result: mapResult(attempt.rating), answered_at: attempt.occurredAt)
                try await client.from("attempts").upsert(payload, onConflict: "id", ignoreDuplicates: true).execute()
                try repository.acknowledgeOutbox(id: item.id)
            } catch { try? repository.markOutboxFailure(id: item.id, error: String(describing: error)) }
        }
    }

    private func mapResult(_ rating: String) -> String { rating == "again" ? "incorrect" : "correct" }
}
