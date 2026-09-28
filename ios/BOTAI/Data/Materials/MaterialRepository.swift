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

    func delete(id: UUID) throws { _ = try database.dbQueue.write { db in try MaterialDBRecord.deleteOne(db, key: id.uuidString) } }
}
