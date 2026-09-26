import Foundation
import Observation
import Supabase
struct MyQuiz:Decodable,Identifiable { let id:UUID; let created_at:Date }
@MainActor @Observable final class MyQuizzesStore {
 private(set)var quizzes:[MyQuiz]=[]; private(set)var errorMessage:String?; private let client=SupabaseProvider.client
 func refresh() async { guard let u=try? await client.auth.session.user else{return}; do{quizzes=try await client.from("quizzes").select("id,created_at").eq("creator_user_id",value:u.id.uuidString).order("created_at",ascending:false).execute().value;errorMessage=nil}catch{errorMessage=error.localizedDescription} }
}
