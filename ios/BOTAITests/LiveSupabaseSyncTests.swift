import Foundation
import Supabase
import Testing
@testable import BOTAI

private final class LiveTestSessionStorage: AuthLocalStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data] = [:]
    func store(key: String, value: Data) throws {
        lock.lock(); defer { lock.unlock() }; values[key] = value
    }
    func retrieve(key: String) throws -> Data? {
        lock.lock(); defer { lock.unlock() }; return values[key]
    }
    func remove(key: String) throws {
        lock.lock(); defer { lock.unlock() }; values.removeValue(forKey: key)
    }
}

struct LiveSupabaseSyncTests {
    @Test func publishesUploadsAcknowledgesAndRetriesAgainstDevelopmentServer() async throws {
        // Opt in via BOTAI_RUN_LIVE_SYNC=1 in the Xcode test scheme.
        // Routine local tests must not depend on an external server.
        guard ProcessInfo.processInfo.environment["BOTAI_RUN_LIVE_SYNC"] == "1" else { return }
        let client = SupabaseClient(supabaseURL: SupabaseConfiguration.projectURL,
                                    supabaseKey: SupabaseConfiguration.publishableKey,
                                    options: SupabaseClientOptions(auth: .init(storage: LiveTestSessionStorage())))
        let session = try await client.auth.signInAnonymously()
        let owner = session.user.id
        let database = try AppDatabase()
        let learning = LearningRepository(database: database)
        let mappings = RemoteQuestionMappingRepository(database: database)
        let question = StudyQuestion(id: UUID(), prompt: "BOTAI live sync \(UUID())",
                                     answer: "Verified", kind: .pair,
                                     choices: [], correctChoiceIndexes: [])
        let attempt = Attempt(id: UUID(), questionID: question.id, occurredAt: .now, rating: .good)
        try learning.record(attempt, state: LearningState(), question: question)
        let check: @Sendable () async -> Bool = {
            (try? await client.auth.session.user.id) == owner
        }
        let publisher = RemoteQuestionPublisher(client: client, mappings: mappings,
                                                isCurrentAccount: check)
        #expect(try await client.auth.session.user.id == owner)
        #expect(try await publisher.publish(question))
        #expect(try await publisher.publish(question))
        let backend = SupabaseBackendAPI(client: client)
        let request = try learning.mappedUploadBatch()
        #expect(request.attempts.count == 1)
        let response = try await backend.uploadAttempts(request)
        #expect(response.acknowledgedIDs == [attempt.id])
        let retry = try await backend.uploadAttempts(request)
        #expect(retry.acknowledgedIDs == [attempt.id])
        #expect(try learning.acknowledgeUploadedAttempts(request: request, response: response) == 1)
        #expect(try learning.outboxCount() == 0)
        #expect(try learning.load().0.map(\.id) == [attempt.id])

        // A pending attempt survives without a current card or remote mapping.
        let historical = StudyQuestion(id: UUID(), prompt: "Historical BOTAI \(UUID())",
                                       answer: "Original answer", kind: .reveal,
                                       choices: [], correctChoiceIndexes: [])
        let oldAttempt = Attempt(id: UUID(), questionID: historical.id,
                                 occurredAt: .now, rating: .hard)
        try learning.record(oldAttempt, state: LearningState(), question: historical)
        let sync = SyncService(client: client, repository: learning, mappings: mappings)
        await sync.flush(questions: [])
        #expect(try learning.outboxCount() == 0)
        #expect(try learning.load().0.map(\.id).contains(oldAttempt.id))
    }
}
