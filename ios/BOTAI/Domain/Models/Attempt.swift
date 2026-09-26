import Foundation
enum RecallRating: String, CaseIterable, Sendable { case again, hard, good
 var title: String { switch self { case .again: "Не знаю"; case .hard: "С трудом"; case .good: "Знаю" } }
}
struct Attempt: Identifiable, Sendable, Equatable { let id: UUID; let questionID: UUID; let occurredAt: Date; let rating: RecallRating }
