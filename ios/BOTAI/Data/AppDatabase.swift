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
 static let databaseTableName="materials"; let id:String; var title:String; var subject:String?; var topic:String?; var description:String?; var author:String?; var kind:String; var source:String; var createdAt:Date; var updatedAt:Date
 init(_ x:StudyMaterialRecord){id=x.id.uuidString;title=x.title;subject=x.subject;topic=x.topic;description=x.description;author=x.author;kind=x.kind.rawValue;source=x.source.rawValue;createdAt=x.createdAt;updatedAt=x.updatedAt}
 var domain:StudyMaterialRecord?{guard let id=UUID(uuidString:id),let kind=MaterialKind(rawValue:kind),let source=MaterialSource(rawValue:source) else{return nil};return .init(id:id,title:title,subject:subject,topic:topic,description:description,author:author,kind:kind,source:source,createdAt:createdAt,updatedAt:updatedAt)}
}
struct MaterialFieldDBRecord: Codable, FetchableRecord, PersistableRecord { static let databaseTableName="materialFields"; let id:String;let materialID:String;var key:String;var title:String;var position:Int;init(_ x:MaterialField){id=x.id.uuidString;materialID=x.materialID.uuidString;key=x.key;title=x.title;position=x.position} }
struct KnowledgeRowDBRecord: Codable, FetchableRecord, PersistableRecord { static let databaseTableName="knowledgeRows";let id:String;let materialID:String;var position:Int;var valuesJSON:String;init(_ x:KnowledgeRow){id=x.id.uuidString;materialID=x.materialID.uuidString;position=x.position;valuesJSON=(try? String(data:JSONEncoder().encode(x.values),encoding:.utf8)) ?? "{}"} }
struct QuestionRuleDBRecord: Codable, FetchableRecord, PersistableRecord { static let databaseTableName="questionRules";let id:String;let materialID:String;var kind:String;var promptFieldKey:String;var answerFieldKey:String;var promptTemplate:String?;var promptFieldKeysJSON:String?;var answersJSON:String?;var showCorrectCount:Bool?;var enabled:Bool;init(_ x:QuestionRule){id=x.id.uuidString;materialID=x.materialID.uuidString;kind=x.kind.rawValue;promptFieldKey=x.promptFieldKey;answerFieldKey=x.answerFieldKey;promptTemplate=x.promptTemplate;promptFieldKeysJSON=(try? String(data:JSONEncoder().encode(x.promptFieldKeys),encoding:.utf8));answersJSON=(try? String(data:JSONEncoder().encode(x.answers),encoding:.utf8));showCorrectCount=x.showCorrectCount;enabled=x.enabled}
 var domain:QuestionRule?{guard let id=UUID(uuidString:id),let mid=UUID(uuidString:materialID),let k=QuestionRuleKind(rawValue:kind) else{return nil};let keys=(try? JSONDecoder().decode([String].self,from:Data((promptFieldKeysJSON ?? "[]").utf8))) ?? [promptFieldKey];let ans=(try? JSONDecoder().decode([QuestionAnswerRule].self,from:Data((answersJSON ?? "[]").utf8))) ?? [QuestionAnswerRule(template:"{1}",fieldKeys:[answerFieldKey],correct:true)];return .init(id:id,materialID:mid,kind:k,promptFieldKey:promptFieldKey,answerFieldKey:answerFieldKey,promptTemplate:promptTemplate ?? "{1}",promptFieldKeys:keys,answers:ans,showCorrectCount:showCorrectCount ?? false,enabled:enabled)} }

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
        }
        migrator.registerMigration("v3_material_builder") { db in
            try db.alter(table:"materials") { $0.add(column:"description",.text) }
            try db.alter(table:"questionRules") { t in t.add(column:"promptTemplate",.text);t.add(column:"promptFieldKeysJSON",.text);t.add(column:"answersJSON",.text);t.add(column:"showCorrectCount",.boolean) }
        }
        migrator.registerMigration("v4_material_author") { db in try db.alter(table:"materials") { $0.add(column:"author",.text) } }
        migrator.registerMigration("v5_courses") { db in
            try db.create(table:"courses") { t in t.column("id",.text).primaryKey();t.column("payloadJSON",.text).notNull();t.column("updatedAt",.datetime).notNull() }
        }
        migrator.registerMigration("v6_study_profile") { db in
            try db.create(table:"studyProfile") { t in t.column("id",.integer).primaryKey();t.column("payloadJSON",.text).notNull();t.column("updatedAt",.datetime).notNull() }
        }
        return migrator
    }
}

struct CourseDBRecord: Codable, FetchableRecord, PersistableRecord {
 static let databaseTableName="courses"; let id:String; var payloadJSON:String; var updatedAt:Date
 init(_ x:StudyCourse) throws { id=x.id.uuidString;payloadJSON=String(data:try JSONEncoder().encode(x),encoding:.utf8)!;updatedAt=x.updatedAt }
 var domain:StudyCourse? { try? JSONDecoder().decode(StudyCourse.self,from:Data(payloadJSON.utf8)) }
}

struct StudyProfileDBRecord: Codable, FetchableRecord, PersistableRecord {
 static let databaseTableName="studyProfile"; let id:Int; var payloadJSON:String; var updatedAt:Date
 init(_ x:StudyProfile) throws { id=1;payloadJSON=String(data:try JSONEncoder().encode(x),encoding:.utf8)!;updatedAt=x.updatedAt }
 var domain:StudyProfile? { try? JSONDecoder().decode(StudyProfile.self,from:Data(payloadJSON.utf8)) }
}
