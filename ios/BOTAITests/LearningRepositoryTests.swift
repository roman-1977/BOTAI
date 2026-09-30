import Foundation
import Testing
@testable import BOTAI

struct LearningRepositoryTests {
    @Test func attemptStateAndOutboxAreAtomicAndDurable() throws {
        let database = try AppDatabase()
        let repository = LearningRepository(database: database)
        let qid = UUID(); let attempt = Attempt(id: UUID(), questionID: qid, occurredAt: .now, rating: .good)
        let state = LearningState(intervalDays: 1, streak: 1, nextDueAt: .now.addingTimeInterval(86400))
        try repository.record(attempt, state: state)
        let loaded = try repository.load()
        #expect(loaded.0.count == 1)
        #expect(loaded.0.first?.id == attempt.id)
        #expect(loaded.0.first?.questionID == attempt.questionID)
        #expect(loaded.0.first?.rating == attempt.rating)
        #expect(loaded.1[qid]?.intervalDays == state.intervalDays)
        #expect(loaded.1[qid]?.streak == state.streak)
        #expect(try repository.outboxCount() == 1)
    }
}

struct StudySessionRepositoryTests {
    @Test func studySessionIsDurable() throws {
        let database=try AppDatabase();let repository=LearningRepository(database:database)
        let session=StudySession(id:UUID(),startedAt:Date(timeIntervalSince1970:100),endedAt:Date(timeIntervalSince1970:160),activeSeconds:60,answered:4,correct:3)
        try repository.saveSession(session)
        #expect(try repository.sessions() == [session])
    }
}
