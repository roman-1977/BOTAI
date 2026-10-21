import Foundation
import Testing
@testable import BOTAI

struct BOTAIBackendAPITests {
    @Test func adapterFailsClosedWithoutAuthoritativeQuestionMapping() async throws {
        let adapter = SupabaseBackendAPI()
        let item = BOTAIUploadAttempt(id: UUID(), questionID: UUID(), questionVersionID: UUID(), occurredAt: Date(), result: "correct")
        await #expect(throws: BOTAIBackendError.missingServerQuestionMapping) {
            try await adapter.uploadAttempts(BOTAIUploadAttemptsRequest(attempts: [item]))
        }
    }

    @Test func uploadContractRoundTripsWithoutProviderTypes() throws {
        let item = BOTAIUploadAttempt(id: UUID(), questionID: UUID(), questionVersionID: UUID(), occurredAt: Date(timeIntervalSince1970: 1_700_000_000), result: "correct")
        let request = BOTAIUploadAttemptsRequest(attempts: [item])
        let restored = try JSONDecoder().decode(BOTAIUploadAttemptsRequest.self, from: JSONEncoder().encode(request))
        #expect(restored == request)
        #expect(restored.schemaVersion == 1)
        let response = BOTAIUploadAttemptsResponse(schemaVersion: 1, acknowledgedIDs: [item.id])
        #expect(try JSONDecoder().decode(BOTAIUploadAttemptsResponse.self, from: JSONEncoder().encode(response)) == response)
    }
}
