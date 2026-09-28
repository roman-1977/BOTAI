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


struct MaterialDBRecord: Codable, FetchableRecord, PersistableRecord {
 static let databaseTableName="materials"; let id:String; var title:String; var subject:String?; var topic:String?; var kind:String; var source:String; var createdAt:Date; var updatedAt:Date
 init(_ x:StudyMaterialRecord){id=x.id.uuidString;title=x.title;subject=x.subject;topic=x.topic;kind=x.kind.rawValue;source=x.source.rawValue;createdAt=x.createdAt;updatedAt=x.updatedAt}
 var domain:StudyMaterialRecord?{guard let id=UUID(uuidString:id),let kind=MaterialKind(rawValue:kind),let source=MaterialSource(rawValue:source) else{return nil};return .init(id:id,title:title,subject:subject,topic:topic,kind:kind,source:source,createdAt:createdAt,updatedAt:updatedAt)}
}
struct MaterialFieldDBRecord: Codable, FetchableRecord, PersistableRecord { static let databaseTableName="materialFields"; let id:String;let materialID:String;var key:String;var title:String;var position:Int;init(_ x:MaterialField){id=x.id.uuidString;materialID=x.materialID.uuidString;key=x.key;title=x.title;position=x.position} }
struct KnowledgeRowDBRecord: Codable, FetchableRecord, PersistableRecord { static let databaseTableName="knowledgeRows";let id:String;let materialID:String;var position:Int;var valuesJSON:String;init(_ x:KnowledgeRow){id=x.id.uuidString;materialID=x.materialID.uuidString;position=x.position;valuesJSON=(try? String(data:JSONEncoder().encode(x.values),encoding:.utf8)) ?? "{}"} }
struct QuestionRuleDBRecord: Codable, FetchableRecord, PersistableRecord { static let databaseTableName="questionRules";let id:String;let materialID:String;var kind:String;var promptFieldKey:String;var answerFieldKey:String;var enabled:Bool;init(_ x:QuestionRule){id=x.id.uuidString;materialID=x.materialID.uuidString;kind=x.kind.rawValue;promptFieldKey=x.promptFieldKey;answerFieldKey=x.answerFieldKey;enabled=x.enabled} }

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
        }
        migrator.registerMigration("v2_material_library") { db in
            try db.create(table:"materials"){t in t.column("id",.text).primaryKey();t.column("title",.text).notNull();t.column("subject",.text);t.column("topic",.text);t.column("kind",.text).notNull();t.column("source",.text).notNull();t.column("createdAt",.datetime).notNull();t.column("updatedAt",.datetime).notNull()}
            try db.create(table:"materialFields"){t in t.column("id",.text).primaryKey();t.column("materialID",.text).notNull().references("materials",onDelete:.cascade);t.column("key",.text).notNull();t.column("title",.text).notNull();t.column("position",.integer).notNull();t.uniqueKey(["materialID","key"])}
            try db.create(table:"knowledgeRows"){t in t.column("id",.text).primaryKey();t.column("materialID",.text).notNull().references("materials",onDelete:.cascade);t.column("position",.integer).notNull();t.column("valuesJSON",.text).notNull()}
            try db.create(table:"questionRules"){t in t.column("id",.text).primaryKey();t.column("materialID",.text).notNull().references("materials",onDelete:.cascade);t.column("kind",.text).notNull();t.column("promptFieldKey",.text).notNull();t.column("answerFieldKey",.text).notNull();t.column("enabled",.boolean).notNull()}
            try db.create(index:"idx_rows_material",on:"knowledgeRows",columns:["materialID"]);try db.create(index:"idx_rules_material",on:"questionRules",columns:["materialID"])
        }; return migrator
    }
}
