import Foundation
struct LearningState: Sendable, Equatable { var intervalDays = 0; var streak = 0; var nextDueAt: Date = .distantPast
 mutating func apply(_ rating: RecallRating, now: Date = .now) { switch rating {
 case .again: intervalDays = 0; streak = 0; nextDueAt = now
 case .hard: intervalDays = max(1, intervalDays); streak += 1; nextDueAt = Calendar.current.date(byAdding: .day, value: intervalDays, to: now) ?? now
 case .good: intervalDays = intervalDays == 0 ? 1 : max(2, intervalDays * 2); streak += 1; nextDueAt = Calendar.current.date(byAdding: .day, value: intervalDays, to: now) ?? now } }
}
