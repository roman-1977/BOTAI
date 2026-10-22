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

struct SharedKnowledgeProgressTests {
    @Test @MainActor func bothModesAdvanceSameDurableKnowledgeState() throws {
        let db = try AppDatabase()
        let repository = LearningRepository(database: db)
        let knowledgeID = UUID()
        let card = StudyQuestion(id: UUID(), prompt: "HCl?", answer: "Соляная", kind: .reveal,
                                 choices: [], correctChoiceIndexes: [], knowledgeID: knowledgeID)
        let choice = StudyQuestion(id: UUID(), prompt: "HCl?", answer: "Соляная", kind: .singleChoice,
                                   choices: ["Соляная", "Азотная", "Серная", "Угольная"], correctChoiceIndexes: [0], knowledgeID: knowledgeID)
        let store = LearningStore(questions: [card, choice], repository: repository)
        #expect(store.record(question: card, rating: .good))
        #expect(store.record(question: choice, rating: .good))
        #expect(store.knowledgeStates.count == 1)
        #expect(store.knowledgeStates[knowledgeID]?.streak == 2)
        let restored = LearningStore(questions: [card, choice], repository: repository)
        #expect(restored.knowledgeStates[knowledgeID]?.streak == 2)
        #expect(restored.attempts.count == 2)
        #expect(Set(restored.attempts.map(\.questionID)) == Set([card.id, choice.id]))
        let persistedKnowledgeIDs = try db.dbQueue.read { db in
            try String.fetchAll(db, sql: "SELECT knowledgeID FROM attempts ORDER BY occurredAt")
        }
        #expect(Set(persistedKnowledgeIDs) == [knowledgeID.uuidString])
        #expect(try repository.outboxCount() == 2)
    }

    @Test func legacyProgressIsBackfilledDuringMigration() throws {
        let db = try AppDatabase()
        let repository = LearningRepository(database: db)
        let id = UUID()
        let attempt = Attempt(id: UUID(), questionID: id, occurredAt: .now, rating: .good)
        let state = LearningState(intervalDays: 1, streak: 1, nextDueAt: .now)
        try repository.record(attempt, state: state)
        #expect(try repository.loadKnowledgeStates()[id]?.streak == 1)
    }
}

struct KnowledgeProgressHistoryTests {
    @Test @MainActor func historyPersistsMasteryTransitionsAndPreservesModeAttempts() throws {
        let db = try AppDatabase()
        let repo = LearningRepository(database: db)
        let knowledge = UUID()
        let first = StudyQuestion(id:UUID(),prompt:"Q",answer:"A",kind:.reveal,choices:[],correctChoiceIndexes:[],knowledgeID:knowledge)
        let second = StudyQuestion(id:UUID(),prompt:"Q",answer:"A",kind:.singleChoice,choices:["A","B"],correctChoiceIndexes:[0],knowledgeID:knowledge)
        let store = LearningStore(questions:[first,second],repository:repo)
        #expect(store.record(question:first,rating:.good))
        #expect(store.record(question:second,rating:.good))
        let persisted = try repo.knowledgeHistory()
        #expect(persisted.count == 2)
        #expect(Set(persisted.map(\.knowledgeID)) == [knowledge])
        #expect(Set(persisted.map(\.attemptID)).count == 2)
        #expect(persisted.last?.isKnown == (store.knowledgeStates[knowledge]?.masteryLevel == .known))
        let reopened = LearningStore(questions:[first,second],repository:repo)
        #expect(reopened.knowledgeHistory == persisted)
        #expect(reopened.attempts.count == 2)
        #expect(try repo.outboxCount() == 2)
    }

    @Test func legacyAttemptsAreNotAssignedInventedHistoricalMastery() throws {
        let db = try AppDatabase()
        let repo = LearningRepository(database: db)
        #expect(try repo.knowledgeHistory().isEmpty)
    }
}
