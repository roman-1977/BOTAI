import Foundation
import Supabase
struct Friendship: Decodable, Identifiable { let id:UUID; let requester_user_id:UUID; let addressee_user_id:UUID; let status:String }
private struct FriendshipInsert: Encodable { let requester_user_id:UUID; let addressee_user_id:UUID }
private struct SharedResultInsert: Encodable { let user_id:UUID; let scope:String; let title:String; let questions_answered:Int; let correct_answers:Int; let score:Double? }
actor SocialService {
 private let client=SupabaseProvider.client
 func friendships() async throws -> [Friendship] { try await client.from("friendships").select().execute().value }
 func requestFriend(_ id:UUID) async throws { let u=try await client.auth.session.user; try await client.from("friendships").insert(FriendshipInsert(requester_user_id:u.id,addressee_user_id:id)).execute() }
 func respond(friendshipID:UUID,accept:Bool) async throws { try await client.rpc("respond_friendship",params:["p_friendship_id":friendshipID.uuidString,"p_accept":accept ? "true":"false"]).execute() }
 func share(title:String,answered:Int,correct:Int) async throws { let u=try await client.auth.session.user; let score=answered>0 ? Double(correct)/Double(answered):nil; try await client.from("shared_results").insert(SharedResultInsert(user_id:u.id,scope:"friends",title:title,questions_answered:answered,correct_answers:correct,score:score)).execute() }
}
