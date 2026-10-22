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


extension SupabaseBackendAPI: SessionSummaryBackendAPI {
    private struct SessionSummaryRow: Encodable {
        let user_id: UUID
        let session_id: UUID
        let started_at: Date
        let ended_at: Date
        let active_seconds: Int
        let answered: Int
        let correct: Int
        init(_ summary: CompletedSessionSummary, userID: UUID) {
            user_id = userID
            session_id = summary.sessionID
            started_at = summary.startedAt
            ended_at = summary.endedAt
            active_seconds = summary.activeSeconds
            answered = summary.answered
            correct = summary.correct
        }
    }
    private struct StoredSummaryRow: Decodable {
        let session_id: UUID
        let started_at: Date
        let ended_at: Date
        let active_seconds: Int
        let answered: Int
        let correct: Int
    }

    func uploadSessionSummaries(_ summaries: [CompletedSessionSummary]) async throws -> [UUID] {
        guard !summaries.isEmpty else { return [] }
        let userID = try await client.auth.session.user.id
        let rows = summaries.map { SessionSummaryRow($0, userID: userID) }
        guard try await client.auth.session.user.id == userID else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        try await client.from("completed_session_summaries")
            .upsert(rows, onConflict: "user_id,session_id", ignoreDuplicates: true).execute()
        guard try await client.auth.session.user.id == userID else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        let stored: [StoredSummaryRow] = try await client.from("completed_session_summaries")
            .select("session_id,started_at,ended_at,active_seconds,answered,correct")
            .in("session_id", values: summaries.map(\.sessionID.uuidString)).execute().value
        guard try await client.auth.session.user.id == userID else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        let expected = Dictionary(uniqueKeysWithValues: summaries.map { ($0.sessionID, $0) })
        return stored.compactMap { row in
            guard let summary = expected[row.session_id],
                abs(summary.startedAt.timeIntervalSince(row.started_at)) < 0.001,
                abs(summary.endedAt.timeIntervalSince(row.ended_at)) < 0.001,
                summary.activeSeconds == row.active_seconds,
                summary.answered == row.answered,
                summary.correct == row.correct else { return nil }
            return row.session_id
        }
    }
}
