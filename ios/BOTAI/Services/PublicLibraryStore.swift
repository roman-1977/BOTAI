import Observation
import Supabase

struct PublicQuiz: Decodable, Identifiable, Sendable {
    let id: UUID
    let quiz_id: UUID
    let quiz_version_id: UUID
    let published_at: Date
}

@MainActor @Observable
final class PublicLibraryStore {
    private(set) var publications: [PublicQuiz] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let client = SupabaseProvider.client

    func refresh() async {
        isLoading = true; defer { isLoading = false }
        do {
            publications = try await client.from("publications")
                .select("id,quiz_id,quiz_version_id,published_at")
                .eq("status", value: "published")
                .order("published_at", ascending: false)
                .execute().value
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
