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
}
