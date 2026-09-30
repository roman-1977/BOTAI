import Foundation
import Observation
@MainActor @Observable final class CourseStore {
 private(set) var courses:[StudyCourse]=[]; private let repository:CourseRepository?
 init(repository:CourseRepository?=nil){self.repository=repository;refresh()}
 func refresh(){courses=(try? repository?.courses()) ?? []}
 func create(title:String,description:String,subject:String,audience:String,minutes:Int?,language:String)->StudyCourse { let now=Date();let x=StudyCourse(id:UUID(),title:title,description:description,subject:subject,audience:audience,estimatedMinutes:minutes,author:"Вы",language:language,coverSymbol:"graduationcap.fill",source:.created,sections:[],goals:[],createdAt:now,updatedAt:now);try? repository?.save(x);refresh();return x }
 func save(_ course:StudyCourse){var x=course;x.updatedAt=Date();try? repository?.save(x);refresh()}
 func delete(_ id:UUID){try? repository?.delete(id);refresh()}
 func removeReferences(to materialID:UUID){
  for var course in courses {
   var changed=false
   for si in course.sections.indices {
    for ti in course.sections[si].topics.indices {
     let before=course.sections[si].topics[ti].questionSets.count
     course.sections[si].topics[ti].questionSets.removeAll{$0.materialID==materialID}
     changed = changed || before != course.sections[si].topics[ti].questionSets.count
    }
   }
   for gi in course.goals.indices {
    let before=course.goals[gi].questionSets.count
    course.goals[gi].questionSets.removeAll{$0.materialID==materialID}
    changed = changed || before != course.goals[gi].questionSets.count
   }
   if changed { save(course) }
  }
  refresh()
 }
}
