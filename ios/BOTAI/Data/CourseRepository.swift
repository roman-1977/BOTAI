import Foundation
import GRDB

final class CourseRepository: @unchecked Sendable {
 private let database:AppDatabase; init(database:AppDatabase){self.database=database}
 func courses() throws->[StudyCourse]{try database.dbQueue.read{db in try CourseDBRecord.order(Column("updatedAt").desc).fetchAll(db).compactMap(\.domain)}}
 func save(_ course:StudyCourse)throws{try database.dbQueue.write{db in try CourseDBRecord(course).save(db)}}
 func delete(_ id:UUID)throws{_ = try database.dbQueue.write{db in try CourseDBRecord.deleteOne(db,key:id.uuidString)}}
}
