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
    @Test @MainActor func choiceAttemptsAndInterruptedSessionSurviveRestart() throws {
        let database = try AppDatabase()
        let repository = LearningRepository(database: database)
        let store = LearningStore(questions: [], repository: repository)
        let correctID = UUID()
        let wrongID = UUID()
        let correctQuestion = StudyQuestion(id: correctID, prompt: "Кислота", answer: "Acid", kind: .singleChoice, choices: ["Acid", "Base"], correctChoiceIndexes: [0])
        let wrongQuestion = StudyQuestion(id: wrongID, prompt: "Основание", answer: "Base", kind: .multipleChoice, choices: ["Base", "Acid"], correctChoiceIndexes: [0])
        store.record(question: correctQuestion, rating: .good)
        store.record(question: wrongQuestion, rating: .again)
        let interrupted = StudySession(id: UUID(), startedAt: Date(timeIntervalSince1970: 100), endedAt: Date(timeIntervalSince1970: 130), activeSeconds: 30, answered: 2, correct: 1)
        #expect(store.saveSession(interrupted))
        let restored = LearningStore(questions: [correctQuestion, wrongQuestion], repository: repository)
        #expect(restored.attempts.count == 2)
        #expect(restored.attempts.contains { $0.questionID == correctID && $0.rating == .good })
        #expect(restored.attempts.contains { $0.questionID == wrongID && $0.rating == .again })
        #expect(restored.sessions == [interrupted])
        let updated = StudySession(id: interrupted.id, startedAt: interrupted.startedAt, endedAt: Date(timeIntervalSince1970: 140), activeSeconds: 40, answered: 2, correct: 1)
        #expect(restored.saveSession(updated))
        let reopened = LearningStore(questions: [], repository: repository)
        #expect(reopened.sessions == [updated])
        #expect(reopened.attempts.count == 2)
    }

    @Test func studySessionIsDurable() throws {
        let database=try AppDatabase();let repository=LearningRepository(database:database)
        let session=StudySession(id:UUID(),startedAt:Date(timeIntervalSince1970:100),endedAt:Date(timeIntervalSince1970:160),activeSeconds:60,answered:4,correct:3)
        try repository.saveSession(session)
        #expect(try repository.sessions() == [session])
    }
}

struct MissingLearningStorageTests {
    @Test @MainActor func answerIsNotCountedWhenStorageUnavailable() {
        let question = StudyQuestion(id: UUID(), prompt: "Вопрос", answer: "Ответ", kind: .reveal, choices: [], correctChoiceIndexes: [])
        let store = LearningStore(questions: [question])
        #expect(!store.record(question: question, rating: .good))
        #expect(store.attempts.isEmpty)
        #expect(store.states.isEmpty)
        #expect(store.lastPersistenceError != nil)
    }

    @Test @MainActor func sessionIsNotCountedWhenStorageUnavailable() {
        let store = LearningStore(questions: [])
        let session = StudySession(id: UUID(), startedAt: .now, endedAt: .now, activeSeconds: 12, answered: 1, correct: 1)
        #expect(!store.saveSession(session))
        #expect(store.sessions.isEmpty)
        #expect(store.lastPersistenceError != nil)
    }
}
