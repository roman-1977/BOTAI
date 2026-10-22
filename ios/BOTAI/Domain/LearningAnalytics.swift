import Foundation

struct StudySession: Identifiable, Sendable, Equatable {
    let id: UUID
    let startedAt: Date
    var endedAt: Date
    var activeSeconds: Int
    var answered: Int
    var correct: Int
}

/// Upload contract: aggregate counts only; no question text, IDs or individual answers.
struct CompletedSessionSummary: Codable, Sendable, Equatable {
    let sessionID: UUID
    let startedAt: Date
    let endedAt: Date
    let activeSeconds: Int
    let answered: Int
    let correct: Int

    init(session: StudySession) {
        sessionID = session.id
        startedAt = session.startedAt
        endedAt = session.endedAt
        activeSeconds = session.activeSeconds
        answered = session.answered
        correct = session.correct
    }
}

enum MasteryLevel: Int, Sendable, CaseIterable { case unseen, learning, reinforcing, known }

struct LearningAnalytics: Sendable, Equatable {
    let sessions: [StudySession]
    let attempts: [Attempt]
    let states: [UUID: LearningState]
    var totalSeconds: Int { sessions.reduce(0) { $0 + $1.activeSeconds } }
    var totalAnswered: Int { sessions.reduce(0) { $0 + $1.answered } }
    var totalCorrect: Int { sessions.reduce(0) { $0 + $1.correct } }
    var accuracy: Double { totalAnswered == 0 ? 0 : Double(totalCorrect) / Double(totalAnswered) }
    func seconds(on date: Date, calendar: Calendar = .current) -> Int { sessions.filter { calendar.isDate($0.startedAt,inSameDayAs:date) }.reduce(0){$0+$1.activeSeconds} }
}

extension LearningState {
    var masteryLevel: MasteryLevel {
        if streak >= 3 && intervalDays >= 4 { return .known }
        if streak >= 2 { return .reinforcing }
        return .learning
    }
}
