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

    func sessions() throws -> [StudySession] { try database.dbQueue.read { db in try StudySessionDBRecord.order(Column("startedAt")).fetchAll(db).compactMap(\.domain) } }
    func saveSession(_ session: StudySession) throws { try database.dbQueue.write { db in try StudySessionDBRecord(session).save(db) } }

    func pendingOutbox() throws -> [OutboxRecord] { try database.dbQueue.read { try OutboxRecord.order(Column("createdAt")).fetchAll($0) } }
    func attempt(id: String) throws -> LocalAttemptRecord? { try database.dbQueue.read { try LocalAttemptRecord.fetchOne($0, key: id) } }
    func acknowledgeOutbox(id: String) throws { _ = try database.dbQueue.write { db in try OutboxRecord.deleteOne(db, key: id) } }
    func markOutboxFailure(id: String, error: String) throws {
        try database.dbQueue.write { db in
            guard var item = try OutboxRecord.fetchOne(db, key: id) else { return }
            item.attemptCount += 1; item.lastError = String(error.prefix(240))
            item.nextRetryAt = Date().addingTimeInterval(min(3600, pow(2, Double(item.attemptCount)) * 5))
            try item.update(db)
        }
    }
    func outboxCount() throws -> Int { try database.dbQueue.read { try OutboxRecord.fetchCount($0) } }
}
