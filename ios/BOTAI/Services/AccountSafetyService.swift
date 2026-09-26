import Foundation
import Supabase
private struct DeleteRequest: Encodable { let user_id: UUID }
private struct BlockInsert: Encodable { let blocker_user_id: UUID; let blocked_user_id: UUID }
private struct ReportInsert: Encodable { let reporter_user_id: UUID; let publication_id: UUID; let reason: String; let details: String? }
actor AccountSafetyService {
 private let client=SupabaseProvider.client
 func requestDeletion() async throws { try await client.rpc("request_account_deletion").execute() }
 func block(userID:UUID) async throws { let u=try await client.auth.session.user; try await client.from("user_blocks").upsert(BlockInsert(blocker_user_id:u.id,blocked_user_id:userID)).execute() }
 func report(publicationID:UUID,reason:String="other",details:String?=nil) async throws { let u=try await client.auth.session.user; try await client.from("reports").insert(ReportInsert(reporter_user_id:u.id,publication_id:publicationID,reason:reason,details:details)).execute() }
}
