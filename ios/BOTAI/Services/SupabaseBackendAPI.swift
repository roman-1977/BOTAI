import Foundation
import Supabase

/// Provider adapter: the rest of the application depends only on BOTAIBackendAPI.
/// The caller must first resolve authoritative remote question/version identifiers.
struct SupabaseBackendAPI: BOTAIBackendAPI {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseProvider.client) {
        self.client = client
    }

    func uploadAttempts(_ request: BOTAIUploadAttemptsRequest) async throws -> BOTAIUploadAttemptsResponse {
        guard request.schemaVersion == 1 else { throw BOTAIBackendError.incompatibleSchemaVersion }
        guard !request.attempts.isEmpty else {
            return BOTAIUploadAttemptsResponse(schemaVersion: 1, acknowledgedIDs: [])
        }
        // No server-side mapping or session validation is implemented here yet.
        // Fail closed instead of transmitting unverified local identifiers.
        throw BOTAIBackendError.missingServerQuestionMapping
    }
}
