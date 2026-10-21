import Foundation
import Supabase

/// Publishes a local text card as a private server question and stores its verified IDs.
/// Choice cards require answer-option publication and are deliberately not supported here.
struct RemoteQuestionPublisher: Sendable {
    let client: SupabaseClient
    let mappings: RemoteQuestionMappingRepository
    let isCurrentAccount: @Sendable () async -> Bool

    private struct QuestionInsert: Encodable {
        let id: UUID
        let creator_user_id: UUID
        let question_type: String
    }
    private struct VersionInsert: Encodable {
        let id: UUID
        let question_id: UUID
        let version_number: Int
        let prompt_text: String
        let answer_text: String
        let created_by: UUID
    }

    /// A partially created remote question remains private and is not considered mapped.
    @discardableResult
    func publish(_ question: StudyQuestion) async throws -> Bool {
        guard question.kind == .reveal || question.kind == .pair,
              question.mediaURL == nil, question.promptLaTeX == nil, question.answerLaTeX == nil,
              !question.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !question.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard await isCurrentAccount() else { return false }
        if try mappings.mapping(for: question.id) != nil { return true }
        let userID = try await client.auth.session.user.id
        let remoteID = UUID(), versionID = UUID()
        guard await isCurrentAccount() else { return false }
        try await client.from("questions").insert(QuestionInsert(id: remoteID,
            creator_user_id: userID,
            question_type: question.kind == .pair ? "pair" : "self_check")).execute()
        guard await isCurrentAccount(), try await client.auth.session.user.id == userID else { return false }
        try await client.from("question_versions").insert(VersionInsert(id: versionID,
            question_id: remoteID, version_number: 1, prompt_text: question.prompt,
            answer_text: question.answer, created_by: userID)).execute()
        let verifier = VerifiedQuestionMappingService(lookup: SupabaseQuestionPairLookup(client: client),
            repository: mappings, isCurrentAccount: isCurrentAccount)
        return try await verifier.verifyAndSave(localQuestionID: question.id,
            remoteQuestionID: remoteID, remoteVersionID: versionID)
    }
}
