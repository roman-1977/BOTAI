import Foundation
import Supabase

private struct QuizInsert: Encodable { let id: UUID; let creator_user_id: UUID }
private struct CollaboratorInsert: Encodable { let quiz_id: UUID; let user_id: UUID; let role: String }
private struct QuizVersionInsert: Encodable { let id: UUID; let quiz_id: UUID; let version_number: Int; let title: String; let description: String?; let created_by: UUID }
private struct QuestionInsert: Encodable { let id: UUID; let creator_user_id: UUID; let question_type: String }
private struct QuestionVersionInsert: Encodable { let id: UUID; let question_id: UUID; let version_number: Int; let prompt_text: String; let answer_text: String; let created_by: UUID }
private struct QuizItemInsert: Encodable { let quiz_version_id: UUID; let question_id: UUID; let question_version_id: UUID; let position: Int }
private struct SubmissionInsert: Encodable { let quiz_id: UUID; let quiz_version_id: UUID; let submitted_by: UUID; let author_note: String? }

actor QuizAuthoringService {
    private let client = SupabaseProvider.client
    func createQuiz(title: String, description: String?, cards: [(String,String)]) async throws {
        let user = try await client.auth.session.user; let quiz = UUID(); let version = UUID()
        try await client.from("quizzes").insert(QuizInsert(id: quiz, creator_user_id: user.id)).execute()
        try await client.from("quiz_collaborators").insert(CollaboratorInsert(quiz_id: quiz, user_id: user.id, role: "owner")).execute()
        try await client.from("quiz_versions").insert(QuizVersionInsert(id: version, quiz_id: quiz, version_number: 1, title: title, description: description, created_by: user.id)).execute()
        for (index, card) in cards.enumerated() {
            let question = UUID(), qv = UUID()
            try await client.from("questions").insert(QuestionInsert(id: question, creator_user_id: user.id, question_type: "self_check")).execute()
            try await client.from("question_versions").insert(QuestionVersionInsert(id: qv, question_id: question, version_number: 1, prompt_text: card.0, answer_text: card.1, created_by: user.id)).execute()
            try await client.from("quiz_version_items").insert(QuizItemInsert(quiz_version_id: version, question_id: question, question_version_id: qv, position: index)).execute()
        }
    }
}

extension QuizAuthoringService {
    func submitLatest(quizID: UUID, versionID: UUID, note: String? = nil) async throws {
        let user = try await client.auth.session.user
        try await client.rpc("submit_quiz_for_publication", params: ["p_quiz_id": quizID.uuidString, "p_version_id": versionID.uuidString, "p_note": note ?? ""]).execute()
    }
}
