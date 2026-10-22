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

/// Explicitly opt-in only on a disposable development Supabase project where migrations
/// 0025 and 0026 have been applied. Never run against the production project.
struct LiveSupabaseSyncTests {
    /// Never use the app's configured backend for destructive integration fixtures.
    /// Explicit disposable URL and public key must be provided by the test operator.
    private func makeClient(url: URL, key: String) -> SupabaseClient {
        SupabaseClient(supabaseURL: url, supabaseKey: key,
                       options: SupabaseClientOptions(auth: .init(storage: LiveTestSessionStorage())))
    }

    static func disposableBackendURL(environment: [String: String]) -> URL? {
        guard environment["BOTAI_RUN_LIVE_SYNC"] == "1",
              environment["BOTAI_DISPOSABLE_SUPABASE_CONFIRMED"] == "1",
              let raw = environment["BOTAI_TEST_SUPABASE_URL"],
              let url = URL(string: raw),
              url.scheme == "https" || (url.scheme == "http" && url.host == "127.0.0.1"),
              url.host != SupabaseConfiguration.projectURL.host,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/",
              let key = environment["BOTAI_TEST_SUPABASE_PUBLISHABLE_KEY"],
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              key != SupabaseConfiguration.publishableKey else { return nil }
        return url
    }

    @Test func rejectsProductionAndIncompleteLiveConfiguration() {
        let flags = ["BOTAI_RUN_LIVE_SYNC": "1",
                     "BOTAI_DISPOSABLE_SUPABASE_CONFIRMED": "1",
                     "BOTAI_TEST_SUPABASE_PUBLISHABLE_KEY": "disposable-public-key"]
        #expect(Self.disposableBackendURL(environment: flags) == nil)
        #expect(Self.disposableBackendURL(environment: flags.merging(
            ["BOTAI_TEST_SUPABASE_URL": SupabaseConfiguration.projectURL.absoluteString],
            uniquingKeysWith: { _, new in new })) == nil)
        #expect(Self.disposableBackendURL(environment: flags.merging(
            ["BOTAI_TEST_SUPABASE_URL": "http://example.com"],
            uniquingKeysWith: { _, new in new })) == nil)
        #expect(Self.disposableBackendURL(environment: flags.merging(
            ["BOTAI_TEST_SUPABASE_URL": "http://127.0.0.1:54321"],
            uniquingKeysWith: { _, new in new })) != nil)
        #expect(Self.disposableBackendURL(environment: flags.merging(
            ["BOTAI_TEST_SUPABASE_URL": "https://disposable.example.org"],
            uniquingKeysWith: { _, new in new })) != nil)
    }

    @Test func aggregateOnlyIdempotentUploadAndTwoAccountIsolation() async throws {
        // Require two explicit opt-ins to avoid mutating a configured production project.
        let environment = ProcessInfo.processInfo.environment
        guard let url = Self.disposableBackendURL(environment: environment),
              let key = environment["BOTAI_TEST_SUPABASE_PUBLISHABLE_KEY"] else { return }
        let clientA = makeClient(url: url, key: key)
        let clientB = makeClient(url: url, key: key)
        let accountA = try await clientA.auth.signInAnonymously().user.id
        let accountB = try await clientB.auth.signInAnonymously().user.id
        #expect(accountA != accountB)

        let repository = LearningRepository(database: try AppDatabase())
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now,
                                   activeSeconds: 25, answered: 2, correct: 1)
        let attribution = StudyQuestionAttribution(courseID: UUID(), sectionID: UUID(), topicID: UUID())
        var topics = SessionTopicAccumulator()
        topics.record(correct: true, attribution: attribution)
        topics.record(correct: false, attribution: nil)
        try repository.completeSession(session, topics: topics)
        let adapter = SupabaseBackendAPI(client: clientA)
        let summary = try #require(repository.pendingSessionSummaries().first)
        #expect(try await adapter.uploadSessionSummaries([summary]) == [session.id])
        // Server-side unique key must make the identical retry safe.
        #expect(try await adapter.uploadSessionSummaries([summary]) == [session.id])
        let ownerRows: [LiveSummaryIdentity] = try await clientA.from("completed_session_summaries")
            .select("session_id,user_id").eq("session_id", value: session.id.uuidString).execute().value
        #expect(ownerRows.count == 1)
        #expect(ownerRows.first?.user_id == accountA)
        let foreignRows: [LiveSummaryIdentity] = try await clientB.from("completed_session_summaries")
            .select("session_id,user_id").eq("session_id", value: session.id.uuidString).execute().value
        #expect(foreignRows.isEmpty)
        // A different JWT must not insert a row owned by A (RLS WITH CHECK).
        let forgedParent = LiveForgedSummary(user_id: accountA, session_id: UUID(),
            started_at: session.startedAt, ended_at: session.endedAt,
            active_seconds: 25, answered: 2, correct: 1)
        do {
            try await clientB.from("completed_session_summaries").insert(forgedParent).execute()
            Issue.record("RLS allowed account B to insert a summary owned by account A")
        } catch {
            // Expected: the backend rejects foreign ownership.
        }
        // Topic rows must be verified under the same account and remain idempotent.
        let topicPending = try repository.pendingTopicSessionSummaries()
        #expect(topicPending.isEmpty) // Parent must be ACKed before topic upload.
        // Local history remains after ACK; individual attempts are not uploaded.
        let coordinator = SessionSummarySyncCoordinator(backend: adapter,
            repository: repository, isCurrentAccount: {
                (try? await clientA.auth.session.user.id) == accountA
            })
        #expect(try await coordinator.flush() == 1)
        #expect(try await coordinator.flush() == 0)
        #expect(try repository.sessions().count == 1)
        #expect(try repository.pendingSessionSummaries().isEmpty)
        let topicBackend = SupabaseBackendAPI(client: clientA)
        let topicSync = TopicAggregateSyncCoordinator(backend: topicBackend,
            repository: repository, isCurrentAccount: {
                (try? await clientA.auth.session.user.id) == accountA
            })
        #expect(try await topicSync.flush() == 1)
        #expect(try await topicSync.flush() == 0)
        let ownTopics: [LiveTopicIdentity] = try await clientA.from("completed_session_topic_aggregates")
            .select("session_id,user_id,course_id,section_id,topic_id,answered,correct")
            .eq("session_id", value: session.id.uuidString).execute().value
        #expect(ownTopics.count == 1)
        #expect(ownTopics.first?.user_id == accountA)
        #expect(ownTopics.first?.course_id == attribution.courseID)
        #expect(ownTopics.first?.section_id == attribution.sectionID)
        #expect(ownTopics.first?.topic_id == attribution.topicID)
        #expect(ownTopics.first?.answered == 1)
        #expect(ownTopics.first?.correct == 1)
        let foreignTopics: [LiveTopicIdentity] = try await clientB.from("completed_session_topic_aggregates")
            .select("session_id,user_id,course_id,section_id,topic_id,answered,correct")
            .eq("session_id", value: session.id.uuidString).execute().value
        #expect(foreignTopics.isEmpty)
        let forgedTopic = LiveForgedTopic(user_id: accountA, session_id: session.id,
            course_id: UUID(), section_id: UUID(), topic_id: UUID(),
            answered: 1, correct: 1)
        do {
            try await clientB.from("completed_session_topic_aggregates").insert(forgedTopic).execute()
            Issue.record("RLS allowed account B to insert a topic aggregate owned by account A")
        } catch {
            // Expected: the backend rejects foreign ownership.
        }
    }
}

private struct LiveForgedSummary: Encodable {
    let user_id: UUID
    let session_id: UUID
    let started_at: Date
    let ended_at: Date
    let active_seconds: Int
    let answered: Int
    let correct: Int
}

private struct LiveForgedTopic: Encodable {
    let user_id: UUID
    let session_id: UUID
    let course_id: UUID
    let section_id: UUID
    let topic_id: UUID
    let answered: Int
    let correct: Int
}

private struct LiveTopicIdentity: Decodable {
    let session_id: UUID
    let user_id: UUID
    let course_id: UUID
    let section_id: UUID
    let topic_id: UUID
    let answered: Int
    let correct: Int
}

private struct LiveSummaryIdentity: Decodable {
    let session_id: UUID
    let user_id: UUID
}
