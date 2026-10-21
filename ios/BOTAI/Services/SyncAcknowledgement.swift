import Foundation

/// Only explicit, unique acknowledgements for submitted IDs may remove outbox items.
/// A malformed or incompatible response must leave the entire batch pending.
enum SyncAcknowledgement {
    static func verifiedIDs(request: BOTAIUploadAttemptsRequest, response: BOTAIUploadAttemptsResponse) throws -> Set<UUID> {
        guard request.schemaVersion == 1, response.schemaVersion == 1 else {
            throw BOTAIBackendError.incompatibleSchemaVersion
        }
        let submitted = request.attempts.map(\.id)
        let submittedSet = Set(submitted)
        guard submittedSet.count == submitted.count else { throw BOTAIBackendError.invalidAcknowledgement }
        let acknowledged = Set(response.acknowledgedIDs)
        guard acknowledged.count == response.acknowledgedIDs.count,
              acknowledged.isSubset(of: submittedSet) else {
            throw BOTAIBackendError.invalidAcknowledgement
        }
        return acknowledged
    }
}
