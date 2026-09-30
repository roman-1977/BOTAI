import Foundation
import Testing
@testable import BOTAI

struct LearningStateTests {
    @Test func againMakesQuestionDueNow() {
        let now = Date(timeIntervalSince1970: 1_000)
        var state = LearningState(intervalDays: 8, streak: 4, nextDueAt: .distantFuture)
        state.apply(.again, now: now)
        #expect(state.intervalDays == 0)
        #expect(state.streak == 0)
        #expect(state.nextDueAt == now)
    }

    @Test func goodGrowsInterval() {
        let now = Date(timeIntervalSince1970: 1_000)
        var state = LearningState(intervalDays: 2, streak: 1, nextDueAt: now)
        state.apply(.good, now: now)
        #expect(state.intervalDays == 4)
        #expect(state.streak == 2)
    }
}

struct MasteryLevelTests {
    @Test func masteryUsesRepetitionEvidence() {
        #expect(LearningState(intervalDays:0,streak:0,nextDueAt:.now).masteryLevel == .learning)
        #expect(LearningState(intervalDays:2,streak:2,nextDueAt:.now).masteryLevel == .reinforcing)
        #expect(LearningState(intervalDays:4,streak:3,nextDueAt:.now).masteryLevel == .known)
    }
}
