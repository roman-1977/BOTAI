import Foundation
import Supabase

/// Server lookup must be performed with the current user's JWT and RLS.
/// A missing or inaccessible question/version pair is never accepted as a mapping.
protocol RemoteQuestionPairLookup: Sendable {
    func isVisiblePair(questionID: UUID, versionID: UUID) async throws -> Bool
}

struct SupabaseQuestionPairLookup: RemoteQuestionPairLookup {
    let client: SupabaseClient

    private struct Pair: Decodable { let id: UUID; let question_id: UUID }

    func isVisiblePair(questionID: UUID, versionID: UUID) async throws -> Bool {
        // Fail closed when there is no authenticated session.
        _ = try await client.auth.session
        let rows: [Pair] = try await client.from("question_versions")
            .select("id,question_id")
            .eq("id", value: versionID.uuidString)
            .eq("question_id", value: questionID.uuidString)
            .limit(1)
            .execute().value
        return rows.count == 1 && rows[0].id == versionID && rows[0].question_id == questionID
    }
}

struct VerifiedQuestionMappingService: Sendable {
    let lookup: any RemoteQuestionPairLookup
    let repository: RemoteQuestionMappingRepository
    let isCurrentAccount: @Sendable () async -> Bool

    /// Persistence occurs only after a server-confirmed, RLS-visible pair.
    func verifyAndSave(localQuestionID: UUID, remoteQuestionID: UUID, remoteVersionID: UUID) async throws -> Bool {
        guard await isCurrentAccount() else { return false }
        guard try await lookup.isVisiblePair(questionID: remoteQuestionID, versionID: remoteVersionID) else {
            return false
        }
        // An auth change while the network request was suspended invalidates the lookup.
        guard await isCurrentAccount() else { return false }
        try repository.saveVerified(localQuestionID: localQuestionID,
                                    remoteQuestionID: remoteQuestionID, remoteVersionID: remoteVersionID)
        return true
    }
}
