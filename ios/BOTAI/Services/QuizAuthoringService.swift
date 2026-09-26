import Foundation
import Supabase

private struct StudySetParams: Encodable {
    let p_id: UUID
    let p_title: String
    let p_description: String
    let p_headers: [String]
    let p_rows: [[String]]
    let p_mappings: [[String:Int]]
}

actor QuizAuthoringService {
    private let client = SupabaseProvider.client
    func createQuiz(title: String, description: String?, draft: StudySetDraft) async throws {
        _ = try await client.auth.session
        let maps = draft.mappings.map { ["from":$0.from, "to":$0.to] }
        let id = UUID()
        let params = StudySetParams(p_id:id, p_title:title, p_description:description ?? "", p_headers:draft.headers, p_rows:draft.rows, p_mappings:maps)
        var lastError: Error?
        for attempt in 1...3 {
            do {
                _ = try await client.rpc("create_study_set", params: params).execute()
                return
            } catch {
                lastError = error
                let ns = error as NSError
                guard attempt < 3, ns.domain == NSURLErrorDomain, [NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut].contains(ns.code) else { throw error }
                try await Task.sleep(for: .milliseconds(400 * attempt))
            }
        }
        throw lastError!
    }
    func submitLatest(quizID: UUID, versionID: UUID, note: String? = nil) async throws {
        _ = try await client.auth.session
        try await client.rpc("submit_quiz_for_publication", params:["p_quiz_id":quizID.uuidString,"p_version_id":versionID.uuidString,"p_note":note ?? ""]).execute()
    }
}
