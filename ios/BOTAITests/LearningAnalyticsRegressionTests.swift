import Foundation
import Testing
@testable import BOTAI

struct LearningAnalyticsRegressionTests {
    @Test func totalsAccuracyAndCalendarDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_800_000_000))
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        let sessions = [
            StudySession(id: UUID(), startedAt: day, endedAt: day.addingTimeInterval(50), activeSeconds: 50, answered: 2, correct: 1),
            StudySession(id: UUID(), startedAt: day.addingTimeInterval(200), endedAt: day.addingTimeInterval(280), activeSeconds: 80, answered: 3, correct: 3),
            StudySession(id: UUID(), startedAt: nextDay, endedAt: nextDay.addingTimeInterval(30), activeSeconds: 30, answered: 1, correct: 0)
        ]
        let analytics = LearningAnalytics(sessions: sessions, attempts: [], states: [:])
        #expect(analytics.totalSeconds == 160)
        #expect(analytics.totalAnswered == 6)
        #expect(analytics.totalCorrect == 4)
        #expect(abs(analytics.accuracy - 2.0 / 3.0) < 0.00001)
        #expect(analytics.seconds(on: day, calendar: calendar) == 130)
        #expect(analytics.seconds(on: nextDay, calendar: calendar) == 30)
        #expect(analytics.seconds(on: calendar.date(byAdding: .day, value: -1, to: day)!, calendar: calendar) == 0)
    }

    @Test func emptyHistoryProducesZeroMetrics() {
        let analytics = LearningAnalytics(sessions: [], attempts: [], states: [:])
        #expect(analytics.totalSeconds == 0)
        #expect(analytics.totalAnswered == 0)
        #expect(analytics.totalCorrect == 0)
        #expect(analytics.accuracy == 0)
        #expect(analytics.seconds(on: Date()) == 0)
    }
}
