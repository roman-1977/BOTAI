import Foundation

struct StudyDayPlan: Codable, Equatable, Sendable {
    var weekday: Int
    var minutes: Int
}

struct StudyProfile: Codable, Equatable, Sendable {
    var defaultDailyMinutes: Int
    var customDays: [StudyDayPlan]
    var updatedAt: Date

    static let standard = StudyProfile(defaultDailyMinutes: 30, customDays: [], updatedAt: .now)
    func minutes(for weekday: Int) -> Int { customDays.first(where: { $0.weekday == weekday })?.minutes ?? defaultDailyMinutes }
    var weeklyMinutes: Int { (1...7).reduce(0) { $0 + minutes(for: $1) } }
}
