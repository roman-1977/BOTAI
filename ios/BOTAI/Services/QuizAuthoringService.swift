import Foundation
import Supabase

private struct CardPayload: Encodable { let prompt: String; let answer: String }
private struct CreateQuizParams: Encodable {
    let p_title: String
    let p_description: String
    let p_cards: [CardPayload]
}

actor QuizAuthoringService {
    private let client = SupabaseProvider.client

    func createQuiz(title: String, description: String?, cards: [(String,String)]) async throws {
        _ = try await client.auth.session
        let payload = cards.map { CardPayload(prompt: $0.0, answer: $0.1) }
        let params = CreateQuizParams(p_title: title, p_description: description ?? "", p_cards: payload)
        _ = try await client.rpc("create_quiz_with_cards", params: params).execute()
    }

    func submitLatest(quizID: UUID, versionID: UUID, note: String? = nil) async throws {
        _ = try await client.auth.session
        try await client.rpc("submit_quiz_for_publication", params: ["p_quiz_id": quizID.uuidString, "p_version_id": versionID.uuidString, "p_note": note ?? ""]).execute()
    }
}
