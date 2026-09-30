import Foundation
import GRDB

final class StudyProfileRepository: @unchecked Sendable {
    private let database: AppDatabase
    init(database: AppDatabase) { self.database = database }
    func load() throws -> StudyProfile {
        try database.dbQueue.read { db in
            guard let row = try StudyProfileDBRecord.fetchOne(db, key: 1) else { return .standard }
            return row.domain ?? .standard
        }
    }
    func save(_ profile: StudyProfile) throws {
        try database.dbQueue.write { db in try StudyProfileDBRecord(profile).save(db) }
    }
}
