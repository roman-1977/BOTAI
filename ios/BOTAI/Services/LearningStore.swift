import Foundation
import Observation
@MainActor @Observable final class LearningStore {
 private(set) var attempts: [Attempt] = []; private(set) var states: [UUID: LearningState] = [:]; let questions: [StudyQuestion]
 init(questions: [StudyQuestion] = DemoContent.questions) { self.questions = questions }
 func record(question: StudyQuestion, rating: RecallRating) { attempts.append(.init(id: UUID(), questionID: question.id, occurredAt: .now, rating: rating)); var state = states[question.id] ?? LearningState(); state.apply(rating); states[question.id] = state }
 var completedToday: Int { attempts.filter { Calendar.current.isDateInToday($0.occurredAt) }.count }
}
