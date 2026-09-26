import Foundation
import Observation
import Supabase

struct Goal: Codable, Identifiable, Sendable { let id: UUID; let user_id: UUID; let title: String; let target_date: String? }
private struct GoalInsert: Encodable { let id: UUID; let user_id: UUID; let title: String; let target_date: String? }
@MainActor @Observable final class GoalsStore {
    private(set) var goals:[Goal]=[]; private(set) var errorMessage:String?; private let client=SupabaseProvider.client
    func refresh() async { guard (try? await client.auth.session) != nil else { return }; do { goals = try await client.from("goals").select("id,user_id,title,target_date").is("archived_at",value:nil).order("target_date").execute().value } catch { errorMessage=error.localizedDescription } }
    func attach(goalID:UUID, quizID:UUID) async { do { struct Link:Encodable { let goal_id:UUID; let study_set_id:UUID }; try await client.from("goal_study_sets").upsert(Link(goal_id:goalID,study_set_id:quizID)).execute() } catch { errorMessage=error.localizedDescription } }
    func add(title:String,date:Date?) async { do { let u=try await client.auth.session.user; let ds=date.map{ISO8601DateFormatter().string(from:$0).prefix(10)}.map(String.init); try await client.from("goals").insert(GoalInsert(id:UUID(),user_id:u.id,title:title,target_date:ds)).execute(); await refresh() } catch { errorMessage=error.localizedDescription } }
}
