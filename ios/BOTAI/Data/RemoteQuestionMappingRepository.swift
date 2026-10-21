import Foundation
import GRDB

struct RemoteQuestionMapping: Codable, FetchableRecord, PersistableRecord, Sendable, Equatable {
    static let databaseTableName = "remoteQuestionMappings"
    let localQuestionID: String
    let remoteQuestionID: String
    let remoteQuestionVersionID: String
    let verifiedAt: Date
}

/// Stores server-confirmed IDs only. Never derive remote IDs from local UUIDs.
final class RemoteQuestionMappingRepository: @unchecked Sendable {
    private let database: AppDatabase
    init(database: AppDatabase) { self.database = database }

    func mapping(for localQuestionID: UUID) throws -> RemoteQuestionMapping? {
        try database.dbQueue.read { db in
            try RemoteQuestionMapping.fetchOne(db, key: localQuestionID.uuidString)
        }
    }

    func saveVerified(localQuestionID: UUID, remoteQuestionID: UUID, remoteVersionID: UUID) throws {
        try database.dbQueue.write { db in
            try RemoteQuestionMapping(localQuestionID: localQuestionID.uuidString, remoteQuestionID: remoteQuestionID.uuidString, remoteQuestionVersionID: remoteVersionID.uuidString, verifiedAt: .now).save(db)
        }
    }
}
