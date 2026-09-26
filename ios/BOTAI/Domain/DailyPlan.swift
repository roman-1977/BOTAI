import Foundation

struct DailyPlan: Sendable, Equatable {
    let completed: Int
    let recommended: Int
    let habitMinimum: Int
    let due: Int
    let weak: Int
    let new: Int

    var progress: Double {
        guard recommended > 0 else { return 0 }
        return min(Double(completed) / Double(recommended), 1)
    }

    var isHabitMinimumComplete: Bool { completed >= habitMinimum }
}
