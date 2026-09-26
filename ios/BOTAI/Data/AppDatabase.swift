import Foundation
import GRDB

struct LocalAttemptRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "attempts"
    let id: String
    let questionID: String
    let occurredAt: Date
    let rating: String
}

struct LocalLearningStateRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "learningStates"
    let questionID: String
    var intervalDays: Int
    var streak: Int
    var nextDueAt: Date
}

struct OutboxRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "syncOutbox"
    let id: String
    let entityType: String
    let entityID: String
    let operation: String
    let payloadVersion: Int
    let createdAt: Date
    var attemptCount: Int
    var nextRetryAt: Date?
    var lastError: String?
}

final class AppDatabase: @unchecked Sendable {
    let dbQueue: DatabaseQueue

    init(path: String? = nil) throws {
        if let path { dbQueue = try DatabaseQueue(path: path) } else { dbQueue = try DatabaseQueue() }
        try Self.migrator.migrate(dbQueue)
    }

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1_learning_outbox") { db in
            try db.create(table: "attempts") { t in
                t.column("id", .text).primaryKey(); t.column("questionID", .text).notNull(); t.column("occurredAt", .datetime).notNull(); t.column("rating", .text).notNull()
            }
            try db.create(table: "learningStates") { t in
                t.column("questionID", .text).primaryKey(); t.column("intervalDays", .integer).notNull(); t.column("streak", .integer).notNull(); t.column("nextDueAt", .datetime).notNull()
            }
            try db.create(table: "syncOutbox") { t in
                t.column("id", .text).primaryKey(); t.column("entityType", .text).notNull(); t.column("entityID", .text).notNull(); t.column("operation", .text).notNull(); t.column("payloadVersion", .integer).notNull(); t.column("createdAt", .datetime).notNull(); t.column("attemptCount", .integer).notNull().defaults(to: 0); t.column("nextRetryAt", .datetime); t.column("lastError", .text)
            }
        }; return migrator
    }
}
