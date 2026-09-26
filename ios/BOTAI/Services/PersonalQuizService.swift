import Foundation
import Supabase

struct PersonalQuizDetail: Decodable {
    let id: UUID; let title: String; let description: String?; let headers: [String]; let rows: [[String]]; let mappings: [CardMappingDTO]
    var draft: StudySetDraft { StudySetDraft(headers: headers, rows: rows, mappings: Set(mappings.map { CardMapping(from:$0.from,to:$0.to) })) }
}
struct CardMappingDTO: Codable { let from: Int; let to: Int }

actor PersonalQuizService {
    private let client = SupabaseProvider.client
    func load(_ id: UUID) async throws -> PersonalQuizDetail { try await client.rpc("get_study_set", params:["p_id":id.uuidString]).execute().value }
    func update(_ id: UUID, title: String, description: String?, draft: StudySetDraft) async throws {
        struct P: Encodable { let p_id:UUID; let p_title:String; let p_description:String; let p_headers:[String]; let p_rows:[[String]]; let p_mappings:[CardMappingDTO] }
        let p=P(p_id:id,p_title:title,p_description:description ?? "",p_headers:draft.headers,p_rows:draft.rows,p_mappings:draft.mappings.map{CardMappingDTO(from:$0.from,to:$0.to)})
        _ = try await client.rpc("update_study_set",params:p).execute()
    }
}
