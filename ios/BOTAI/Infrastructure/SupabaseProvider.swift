import Foundation
import Supabase

enum SupabaseProvider {
    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }()

    static let client = SupabaseClient(
        supabaseURL: SupabaseConfiguration.projectURL,
        supabaseKey: SupabaseConfiguration.publishableKey,
        options: SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true),
            global: .init(session: session)
        )
    )
}
