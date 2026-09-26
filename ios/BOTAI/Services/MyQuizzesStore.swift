import Foundation
import Observation
import Supabase
struct MyQuiz:Decodable,Identifiable { let quiz_id:UUID;let quiz_version_id:UUID;let title:String;let description:String?;let version_number:Int;let created_at:Date;let submission_status:String?;var id:UUID{quiz_id} }
@MainActor @Observable final class MyQuizzesStore { private(set)var quizzes:[MyQuiz]=[];private(set)var errorMessage:String?;private let client=SupabaseProvider.client
 func refresh()async{guard(try? await client.auth.session) != nil else{return};do{quizzes=try await client.rpc("my_study_sets").execute().value;errorMessage=nil}catch{errorMessage=error.localizedDescription}}
 func submit(_ q:MyQuiz)async{do{try await QuizAuthoringService().submitLatest(quizID:q.quiz_id,versionID:q.quiz_version_id);await refresh()}catch{errorMessage=error.localizedDescription}}
}
