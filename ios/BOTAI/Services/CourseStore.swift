import Foundation
import Observation
@MainActor @Observable final class CourseStore {
 private(set) var courses:[StudyCourse]=[]; private let repository:CourseRepository?
 init(repository:CourseRepository?=nil){self.repository=repository;refresh()}
 func refresh(){courses=(try? repository?.courses()) ?? []}
 func create(title:String,description:String,subject:String,audience:String,minutes:Int?,language:String)->StudyCourse { let now=Date();let x=StudyCourse(id:UUID(),title:title,description:description,subject:subject,audience:audience,estimatedMinutes:minutes,author:"Вы",language:language,coverSymbol:"graduationcap.fill",source:.created,sections:[],createdAt:now,updatedAt:now);try? repository?.save(x);refresh();return x }
 func save(_ course:StudyCourse){var x=course;x.updatedAt=Date();try? repository?.save(x);refresh()}
 func delete(_ id:UUID){try? repository?.delete(id);refresh()}
}
