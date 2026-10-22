import Foundation

/// Transport-neutral contract for the BOTAI server. No Supabase types cross this boundary.
/// Versioned request/response models allow a future PostgreSQL host migration.
protocol BOTAIBackendAPI: Sendable {
    func uploadAttempts(_ request: BOTAIUploadAttemptsRequest) async throws -> BOTAIUploadAttemptsResponse
}

struct BOTAIUploadAttemptsRequest: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let attempts: [BOTAIUploadAttempt]

    init(attempts: [BOTAIUploadAttempt]) {
        schemaVersion = 1
        self.attempts = attempts
    }
}

struct BOTAIUploadAttempt: Codable, Sendable, Equatable {
    let id: UUID
    let questionID: UUID
    let questionVersionID: UUID
    let occurredAt: Date
    let result: String
}

struct BOTAIUploadAttemptsResponse: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let acknowledgedIDs: [UUID]
}

/// Uploads must not be attempted until local questions are mapped to authoritative server IDs.
enum BOTAIBackendError: Error, Equatable {
    case missingServerQuestionMapping
    case incompatibleSchemaVersion
    case invalidAcknowledgement
}

/// Separate from legacy per-answer transport. Only completed-session aggregates cross the wire.
protocol SessionSummaryBackendAPI: Sendable {
    func uploadSessionSummaries(_ summaries: [CompletedSessionSummary]) async throws -> [UUID]
}

protocol TopicAggregateBackendAPI: Sendable {
    /// Return session IDs only when every attributed topic row was verified.
    func uploadTopicAggregates(_ summaries: [CompletedSessionSummary]) async throws -> [UUID]
}
