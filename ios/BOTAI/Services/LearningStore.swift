import Foundation
import Observation

@MainActor @Observable
final class LearningStore {
    private(set) var attempts: [Attempt] = []
    private(set) var states: [UUID: LearningState] = [:]
    let questions: [StudyQuestion]
    private let repository: LearningRepository?

    init(questions: [StudyQuestion] = DemoContent.questions, repository: LearningRepository? = nil) {
        self.questions = questions
        self.repository = repository
        if let repository, let saved = try? repository.load() { attempts = saved.0; states = saved.1 }
    }

    func record(question: StudyQuestion, rating: RecallRating) {
        let attempt = Attempt(id: UUID(), questionID: question.id, occurredAt: .now, rating: rating)
        var state = states[question.id] ?? LearningState(); state.apply(rating)
        if let repository { try? repository.record(attempt, state: state) }
        attempts.append(attempt); states[question.id] = state
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
