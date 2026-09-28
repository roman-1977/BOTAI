import Foundation
import GRDB

final class MaterialRepository: @unchecked Sendable {
    private let database: AppDatabase
    init(database: AppDatabase) { self.database = database }

    func materials() throws -> [StudyMaterialRecord] {
        try database.dbQueue.read { db in
            try MaterialDBRecord.order(Column("updatedAt").desc).fetchAll(db).compactMap(\.domain)
        }
    }

    func save(material: StudyMaterialRecord, fields: [MaterialField], rows: [KnowledgeRow], rules: [QuestionRule]) throws {
        try database.dbQueue.write { db in
            try MaterialDBRecord(material).save(db)
            try MaterialFieldDBRecord.filter(Column("materialID") == material.id.uuidString).deleteAll(db)
            try KnowledgeRowDBRecord.filter(Column("materialID") == material.id.uuidString).deleteAll(db)
            try QuestionRuleDBRecord.filter(Column("materialID") == material.id.uuidString).deleteAll(db)
            for field in fields { try MaterialFieldDBRecord(field).insert(db) }
            for row in rows { try KnowledgeRowDBRecord(row).insert(db) }
            for rule in rules { try QuestionRuleDBRecord(rule).insert(db) }
        }
    }

    func delete(id: UUID) throws { _ = try database.dbQueue.write { db in try MaterialDBRecord.deleteOne(db, key: id.uuidString) } }
}
