import Foundation
import GRDB

final class LearningRepository: @unchecked Sendable {
    private let database: AppDatabase
    init(database: AppDatabase) { self.database = database }

    func load() throws -> ([Attempt], [UUID: LearningState]) {
        try database.dbQueue.read { db in
            let attempts = try LocalAttemptRecord.fetchAll(db).compactMap { r -> Attempt? in
                guard let id = UUID(uuidString: r.id), let qid = UUID(uuidString: r.questionID), let rating = RecallRating(rawValue: r.rating) else { return nil }
                return Attempt(id: id, questionID: qid, occurredAt: r.occurredAt, rating: rating)
            }
            let pairs = try LocalLearningStateRecord.fetchAll(db).compactMap { r -> (UUID, LearningState)? in
                guard let id = UUID(uuidString: r.questionID) else { return nil }; return (id, LearningState(intervalDays: r.intervalDays, streak: r.streak, nextDueAt: r.nextDueAt))
            }
            return (attempts, Dictionary(uniqueKeysWithValues: pairs))
        }
    }

    func record(_ attempt: Attempt, state: LearningState) throws {
        try database.dbQueue.write { db in
            try LocalAttemptRecord(id: attempt.id.uuidString, questionID: attempt.questionID.uuidString, occurredAt: attempt.occurredAt, rating: attempt.rating.rawValue).insert(db)
            try LocalLearningStateRecord(questionID: attempt.questionID.uuidString, intervalDays: state.intervalDays, streak: state.streak, nextDueAt: state.nextDueAt).save(db)
            try OutboxRecord(id: UUID().uuidString, entityType: "attempt", entityID: attempt.id.uuidString, operation: "upsert", payloadVersion: 1, createdAt: .now, attemptCount: 0, nextRetryAt: nil, lastError: nil).insert(db)
        }
    }

    func outboxCount() throws -> Int { try database.dbQueue.read { try OutboxRecord.fetchCount($0) } }
}
