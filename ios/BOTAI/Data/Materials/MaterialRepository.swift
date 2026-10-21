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
            // Editing a material can change the rendered question while preserving its
            // stable local ID (ruleID + rowID). Revoke verified server mappings before
            // changing any rows/rules; otherwise old remote content receives new attempts.
            let oldRules = try QuestionRuleDBRecord.filter(Column("materialID") == material.id.uuidString).fetchAll(db)
            let oldRows = try KnowledgeRowDBRecord.filter(Column("materialID") == material.id.uuidString).fetchAll(db)
            let allRuleIDs = Set(oldRules.compactMap { UUID(uuidString: $0.id) } + rules.map(\.id))
            let allRowIDs = Set(oldRows.compactMap { UUID(uuidString: $0.id) } + rows.map(\.id))
            for ruleID in allRuleIDs {
                for rowID in allRowIDs {
                    let localID = StudyQuestionBuilder.stableID(ruleID: ruleID, rowID: rowID)
                    try freezePendingAttemptMappings(db, localID: localID)
                    _ = try RemoteQuestionMapping.deleteOne(db, key: localID.uuidString)
                }
            }
            try MaterialDBRecord(material).save(db)
            try MaterialFieldDBRecord.filter(Column("materialID") == material.id.uuidString).deleteAll(db)
            try KnowledgeRowDBRecord.filter(Column("materialID") == material.id.uuidString).deleteAll(db)
            try QuestionRuleDBRecord.filter(Column("materialID") == material.id.uuidString).deleteAll(db)
            for field in fields { try MaterialFieldDBRecord(field).insert(db) }
            for row in rows { try KnowledgeRowDBRecord(row).insert(db) }
            for rule in rules { try QuestionRuleDBRecord(rule).insert(db) }
        }
    }

    func content(id: UUID) throws -> MaterialContent? {
        try database.dbQueue.read { db in
            guard let m = try MaterialDBRecord.fetchOne(db, key: id.uuidString)?.domain else { return nil }
            let fs = try MaterialFieldDBRecord.filter(Column("materialID") == id.uuidString).order(Column("position")).fetchAll(db).compactMap { r in UUID(uuidString:r.id).flatMap { fid in UUID(uuidString:r.materialID).map { MaterialField(id:fid,materialID:$0,key:r.key,title:r.title,position:r.position) } } }
            let rs = try KnowledgeRowDBRecord.filter(Column("materialID") == id.uuidString).order(Column("position")).fetchAll(db).compactMap { r -> KnowledgeRow? in guard let rid=UUID(uuidString:r.id),let mid=UUID(uuidString:r.materialID),let data=r.valuesJSON.data(using:.utf8),let vals=try? JSONDecoder().decode([String:String].self,from:data) else{return nil};return .init(id:rid,materialID:mid,position:r.position,values:vals) }
            let qs = try QuestionRuleDBRecord.filter(Column("materialID") == id.uuidString).fetchAll(db).compactMap(\.domain)
            return MaterialContent(material:m,fields:fs,rows:rs,rules:qs)
        }
    }

    func migrateLegacyMediaReferences() throws {
        try database.dbQueue.write { db in
            let records = try KnowledgeRowDBRecord.fetchAll(db)
            for record in records {
                guard let mid=UUID(uuidString:record.materialID),let data=record.valuesJSON.data(using:.utf8),var values=try? JSONDecoder().decode([String:String].self,from:data) else { continue }
                var changed=false
                for (key,value) in values where MaterialMediaStore.isImageReference(value) && !value.hasPrefix(MaterialMediaStore.prefix) {
                    if let url=MaterialMediaStore.resolvedURL(for:value) { values[key]=MaterialMediaStore.reference(materialID:mid,fileName:url.lastPathComponent);changed=true }
                }
                if changed { var updated=record;updated.valuesJSON=String(data:try JSONEncoder().encode(values),encoding:.utf8)!;try updated.update(db) }
            }
        }
    }

    private func freezePendingAttemptMappings(_ db: Database, localID: UUID) throws {
        guard let mapping = try RemoteQuestionMapping.fetchOne(db, key: localID.uuidString) else {
            // Historical attempts without a published server version must never be
            // assigned the newly edited card's mapping. Keep them locally for recovery.
            try db.execute(sql: """
                UPDATE attempts SET invalidatedBeforePublication = 1
                WHERE questionID = ? AND remoteQuestionID IS NULL
                """, arguments: [localID.uuidString])
            return
        }
        // Preserve the exact server version used by historical attempts before
        // invalidating the current card mapping on edit or deletion.
        try db.execute(sql: """
            UPDATE attempts SET remoteQuestionID = ?, remoteVersionID = ?
            WHERE questionID = ? AND remoteQuestionID IS NULL
            """, arguments: [mapping.remoteQuestionID, mapping.remoteQuestionVersionID, localID.uuidString])
    }

    func delete(id: UUID) throws {
        try database.dbQueue.write { db in
            let rules = try QuestionRuleDBRecord.filter(Column("materialID") == id.uuidString).fetchAll(db)
            let rows = try KnowledgeRowDBRecord.filter(Column("materialID") == id.uuidString).fetchAll(db)
            for rule in rules {
                for row in rows {
                    guard let ruleID = UUID(uuidString: rule.id), let rowID = UUID(uuidString: row.id) else { continue }
                    let localID = StudyQuestionBuilder.stableID(ruleID: ruleID, rowID: rowID)
                    try freezePendingAttemptMappings(db, localID: localID)
                    _ = try RemoteQuestionMapping.deleteOne(db, key: localID.uuidString)
                }
            }
            _ = try MaterialDBRecord.deleteOne(db, key: id.uuidString)
        }
    }
}
