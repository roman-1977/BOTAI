import Foundation
import Observation
import Supabase
struct PublicQuiz:Decodable,Identifiable,Sendable { let publication_id:UUID;let quiz_id:UUID;let quiz_version_id:UUID;let title:String;let description:String?;let published_at:Date;var id:UUID{publication_id} }
@MainActor @Observable final class PublicLibraryStore { private(set)var publications:[PublicQuiz]=[];private(set)var isLoading=false;private(set)var errorMessage:String?;private let client=SupabaseProvider.client
 func refresh()async{isLoading=true;defer{isLoading=false};do{publications=try await client.rpc("public_library").execute().value;errorMessage=nil}catch{errorMessage=error.localizedDescription}}
}
