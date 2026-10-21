import Foundation
import Supabase

/// Provider adapter: local IDs are never uploaded as remote question identifiers.
/// Every supplied remote question/version pair is checked under the current JWT and RLS.
struct SupabaseBackendAPI: BOTAIBackendAPI {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseProvider.client) {
        self.client = client
    }

    private struct AttemptRow: Encodable {
        let id: UUID
        let user_id: UUID
        let question_id: UUID
        let question_version_id: UUID
        let result: String
        let answered_at: Date
    }

    private struct StoredAttempt: Decodable {
        let id: UUID
        let question_id: UUID
        let question_version_id: UUID
        let result: String
    }

    func uploadAttempts(_ request: BOTAIUploadAttemptsRequest) async throws -> BOTAIUploadAttemptsResponse {
        guard request.schemaVersion == 1 else { throw BOTAIBackendError.incompatibleSchemaVersion }
        guard !request.attempts.isEmpty else {
            return BOTAIUploadAttemptsResponse(schemaVersion: 1, acknowledgedIDs: [])
        }
        let userID = try await client.auth.session.user.id
        let verifier = SupabaseQuestionPairLookup(client: client)
        var verifiedPairs = Set<String>()
        for attempt in request.attempts {
            let pair = "\(attempt.questionID.uuidString):\(attempt.questionVersionID.uuidString)"
            if verifiedPairs.insert(pair).inserted {
                guard try await verifier.isVisiblePair(questionID: attempt.questionID,
                                                       versionID: attempt.questionVersionID) else {
                    throw BOTAIBackendError.missingServerQuestionMapping
                }
            }
        }
        guard try await client.auth.session.user.id == userID else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        let rows = request.attempts.map {
            AttemptRow(id: $0.id, user_id: userID, question_id: $0.questionID,
                       question_version_id: $0.questionVersionID, result: $0.result,
                       answered_at: $0.occurredAt)
        }
        // Ignore duplicate IDs on retries. No UPDATE privilege is granted to clients.
        try await client.from("attempts")
            .upsert(rows, onConflict: "id", ignoreDuplicates: true)
            .execute()
        guard try await client.auth.session.user.id == userID else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        // ACK only IDs actually visible to this user after the insert.
        let ids = request.attempts.map(\.id.uuidString)
        let stored: [StoredAttempt] = try await client.from("attempts")
            .select("id,question_id,question_version_id,result")
            .in("id", values: ids)
            .execute().value
        guard try await client.auth.session.user.id == userID else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        let expected = Dictionary(uniqueKeysWithValues: request.attempts.map { ($0.id, $0) })
        let confirmed = Set(stored.compactMap { row -> UUID? in
            guard let attempt = expected[row.id],
                  attempt.questionID == row.question_id,
                  attempt.questionVersionID == row.question_version_id,
                  attempt.result == row.result else { return nil }
            return row.id
        })
        return BOTAIUploadAttemptsResponse(schemaVersion: 1, acknowledgedIDs: Array(confirmed))
    }
}
