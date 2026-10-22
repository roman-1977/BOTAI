import Foundation
import Observation

/// Exact ordered questions and cursor for one interrupted session, scoped to the local account database.
struct ResumableStudySession: Codable, Equatable {
    let id: UUID
    let startedAt: Date
    let title: String
    let targetMinutes: Int
    let questions: [StudyQuestion]
    var nextIndex: Int
    var answered: Int
    var correct: Int
    var activeSeconds: Int
    var attributionByQuestion: [UUID: StudyQuestionAttribution]? = nil
    var topicAccumulator: SessionTopicAccumulator? = nil

    var canResume: Bool { !questions.isEmpty && questions.indices.contains(nextIndex) }
}

@MainActor @Observable
final class LearningStore {
    private(set) var attempts: [Attempt] = []
    private(set) var states: [UUID: LearningState] = [:]
    private(set) var knowledgeStates: [UUID: LearningState] = [:]
    private(set) var knowledgeHistory: [LearningRepository.KnowledgeProgressEvent] = []
    private(set) var forecastHistory: [LearningRepository.ForecastSnapshot] = []
    private(set) var sessions: [StudySession] = []
    private(set) var completedSessionSignal = 0
    private(set) var questions: [StudyQuestion]
    private(set) var sessionTitle: String = "Обучение"
    private(set) var attributionByQuestion: [UUID: StudyQuestionAttribution] = [:]
    private(set) var sessionTargetMinutes: Int = 0
    private(set) var resumableSession: ResumableStudySession?
    private let repository: LearningRepository?
    private(set) var lastPersistenceError: String?

    init(questions: [StudyQuestion] = DemoContent.questions, repository: LearningRepository? = nil) {
        self.questions = questions
        self.repository = repository
        if let repository {
            do {
                let saved = try repository.load()
                let savedSessions = try repository.sessions()
                attempts = saved.0
                states = saved.1
                knowledgeStates = try repository.loadKnowledgeStates()
                knowledgeHistory = try repository.knowledgeHistory()
                forecastHistory = try repository.forecastSnapshots()
                sessions = savedSessions
                let snapshot = try repository.loadResumableSession()
                resumableSession = snapshot?.canResume == true ? snapshot : nil
            } catch {
                lastPersistenceError = error.localizedDescription
            }
        }
    }

    @discardableResult
    func saveForecast(_ snapshot: LearningRepository.ForecastSnapshot) -> Bool {
        guard let repository else { lastPersistenceError = "Локальное хранилище недоступно"; return false }
        do { try repository.saveForecast(snapshot) }
        catch { lastPersistenceError = error.localizedDescription; return false }
        forecastHistory.removeAll { $0.goalID == snapshot.goalID && $0.day == snapshot.day }
        forecastHistory.append(snapshot)
        return true
    }

    func use(questions: [StudyQuestion], title: String = "Обучение", targetMinutes: Int = 0, attributionByQuestion: [UUID: StudyQuestionAttribution] = [:]) { self.questions = questions; sessionTitle = title; sessionTargetMinutes = targetMinutes; self.attributionByQuestion = attributionByQuestion }

    @discardableResult
    func checkpoint(_ snapshot: ResumableStudySession?) -> Bool {
        guard let repository else { lastPersistenceError = "Локальное хранилище недоступно"; return false }
        do {
            try repository.saveResumableSession(snapshot)
            resumableSession = snapshot
            lastPersistenceError = nil
            return true
        } catch {
            lastPersistenceError = error.localizedDescription
            return false
        }
    }

    func restoreResumableSession() -> ResumableStudySession? {
        guard let snapshot = resumableSession, snapshot.canResume else { return nil }
        use(questions: snapshot.questions, title: snapshot.title, targetMinutes: snapshot.targetMinutes, attributionByQuestion: snapshot.attributionByQuestion ?? [:])
        return snapshot
    }

    func attempts(for questionIDs: Set<UUID>) -> [Attempt] { attempts.filter { questionIDs.contains($0.questionID) } }
    func stats(for questions: [StudyQuestion]) -> QuizLearningStats {
        let ids=Set(questions.map(\.id)); let a=attempts(for:ids); let learned=questions.filter{states[$0.id] != nil}.count
        let known=a.filter{$0.rating == .good}.count; let hard=a.filter{$0.rating == .hard}.count; let again=a.filter{$0.rating == .again}.count
        return QuizLearningStats(total:questions.count,learned:learned,attempts:a.count,known:known,hard:hard,again:again,today:a.filter{Calendar.current.isDateInToday($0.occurredAt)}.count)
    }

    @discardableResult
    func saveSession(_ session: StudySession) -> Bool {
        guard session.answered > 0 || session.activeSeconds > 0 else { return true }
        guard let repository else {
            lastPersistenceError = "Локальное хранилище недоступно"
            return false
        }
        do { try repository.saveSession(session); lastPersistenceError = nil }
        catch { lastPersistenceError = error.localizedDescription; return false }
        if let i=sessions.firstIndex(where:{$0.id == session.id}) { sessions[i]=session } else { sessions.append(session) }
        return true
    }
    @discardableResult
    func completeSession(_ session: StudySession, topics: SessionTopicAccumulator? = nil) -> Bool {
        guard let repository else {
            lastPersistenceError = "Локальное хранилище недоступно"
            return false
        }
        do { try repository.completeSession(session, topics: topics); lastPersistenceError = nil }
        catch { lastPersistenceError = error.localizedDescription; return false }
        resumableSession = nil
        if let i = sessions.firstIndex(where: { $0.id == session.id }) { sessions[i] = session }
        else { sessions.append(session) }
        completedSessionSignal += 1
        return true
    }

    var analytics: LearningAnalytics { LearningAnalytics(sessions:sessions,attempts:attempts,states:states) }
    var knownCount:Int { knowledgeStates.values.filter{$0.masteryLevel == .known}.count }
    var masteryPercent:Int { knowledgeStates.isEmpty ? 0 : Int((Double(knownCount)/Double(knowledgeStates.count)*100).rounded()) }

    @discardableResult
    func record(question: StudyQuestion, rating: RecallRating, advancingTo snapshot: ResumableStudySession? = nil) -> Bool {
        let attempt = Attempt(id: UUID(), questionID: question.id, occurredAt: .now, rating: rating)
        var state = knowledgeStates[question.knowledgeID] ?? LearningState(); state.apply(rating)
        // Never report an answer as saved if the durable local write failed.
        // Otherwise the UI advances while the sync outbox silently loses the event.
        guard let repository else {
            lastPersistenceError = "Локальное хранилище недоступно"
            return false
        }
        do { try repository.record(attempt, state: state, question: question, nextSession: snapshot) }
        catch {
            lastPersistenceError = error.localizedDescription
            return false
        }
        if let snapshot { resumableSession = snapshot.canResume ? snapshot : nil }
        attempts.append(attempt); states[question.id] = state; knowledgeStates[question.knowledgeID] = state
        knowledgeHistory.append(.init(attemptID: attempt.id, knowledgeID: question.knowledgeID,
                                      occurredAt: attempt.occurredAt, isKnown: state.masteryLevel == .known))
        lastPersistenceError = nil
        return true
    }

    var completedToday: Int { attempts.filter { Calendar.current.isDateInToday($0.occurredAt) }.count }
    func count(daysBack: Int, length: Int) -> Int {
        let cal = Calendar.current; let today = cal.startOfDay(for: .now)
        guard let end = cal.date(byAdding: .day, value: -daysBack, to: today), let start = cal.date(byAdding: .day, value: -length, to: end) else { return 0 }
        return attempts.filter { $0.occurredAt >= start && $0.occurredAt < end }.count
    }
    var thisWeek: Int { count(daysBack: -1, length: 7) }
    var dailyRecommended: Int { max(10, min(40, knowledgeStates.values.filter { $0.nextDueAt <= .now }.count + 10)) }
    var dueCount: Int { knowledgeStates.values.filter { $0.nextDueAt <= .now }.count }
    var weakCount: Int { knowledgeStates.values.filter { $0.streak == 0 }.count }
    var newCount: Int { max(0, questions.count - states.count) }
    var previousWeek: Int { count(daysBack: 6, length: 7) }
    var streak: Int {
        let cal=Calendar.current; let days=Set(attempts.map{cal.startOfDay(for:$0.occurredAt)}); var n=0; var d=cal.startOfDay(for:.now)
        while days.contains(d) { n += 1; d=cal.date(byAdding:.day,value:-1,to:d)! }; return n
    }
}
