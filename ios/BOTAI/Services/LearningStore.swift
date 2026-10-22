import Foundation
import Observation

@MainActor @Observable
final class LearningStore {
    private(set) var attempts: [Attempt] = []
    private(set) var states: [UUID: LearningState] = [:]
    private(set) var knowledgeStates: [UUID: LearningState] = [:]
    private(set) var sessions: [StudySession] = []
    private(set) var questions: [StudyQuestion]
    private(set) var sessionTitle: String = "Обучение"
    private(set) var sessionTargetMinutes: Int = 0
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
                sessions = savedSessions
            } catch {
                lastPersistenceError = error.localizedDescription
            }
        }
    }

    func use(questions: [StudyQuestion], title: String = "Обучение", targetMinutes: Int = 0) { self.questions = questions; sessionTitle = title; sessionTargetMinutes = targetMinutes }

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
    var analytics: LearningAnalytics { LearningAnalytics(sessions:sessions,attempts:attempts,states:states) }
    var knownCount:Int { states.values.filter{$0.masteryLevel == .known}.count }
    var masteryPercent:Int { states.isEmpty ? 0 : Int((Double(knownCount)/Double(states.count)*100).rounded()) }

    @discardableResult
    func record(question: StudyQuestion, rating: RecallRating) -> Bool {
        let attempt = Attempt(id: UUID(), questionID: question.id, occurredAt: .now, rating: rating)
        var state = knowledgeStates[question.knowledgeID] ?? LearningState(); state.apply(rating)
        // Never report an answer as saved if the durable local write failed.
        // Otherwise the UI advances while the sync outbox silently loses the event.
        guard let repository else {
            lastPersistenceError = "Локальное хранилище недоступно"
            return false
        }
        do { try repository.record(attempt, state: state, question: question) }
        catch {
            lastPersistenceError = error.localizedDescription
            return false
        }
        attempts.append(attempt); states[question.id] = state; knowledgeStates[question.knowledgeID] = state
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
    var dailyRecommended: Int { max(10, min(40, states.values.filter { $0.nextDueAt <= .now }.count + 10)) }
    var dueCount: Int { states.values.filter { $0.nextDueAt <= .now }.count }
    var weakCount: Int { states.values.filter { $0.streak == 0 }.count }
    var newCount: Int { max(0, questions.count - states.count) }
    var previousWeek: Int { count(daysBack: 6, length: 7) }
    var streak: Int {
        let cal=Calendar.current; let days=Set(attempts.map{cal.startOfDay(for:$0.occurredAt)}); var n=0; var d=cal.startOfDay(for:.now)
        while days.contains(d) { n += 1; d=cal.date(byAdding:.day,value:-1,to:d)! }; return n
    }
}
