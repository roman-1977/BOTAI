import Foundation

enum DailyPlanner {
 @MainActor static func make(courses:[StudyCourse],materials:MaterialStore,learning:LearningStore,profile:StudyProfile,date:Date = .now)->DailyStudyPlan {
   let weekday=Calendar.current.component(.weekday,from:date),budget=profile.minutes(for:weekday)
   struct Candidate { let course:StudyCourse;let goal:LearningGoal;let questions:[StudyQuestion];let mastery:Int;let urgency:Double }
   var cs:[Candidate]=[]
   for c in courses { for g in c.goals where g.state == .active {
     let qs=g.questionSets.flatMap{ref -> [StudyQuestion] in guard let content=materials.content(id:ref.materialID) else{return []};return StudyQuestionBuilder.questions(for:ref,content:content)}
     guard !qs.isEmpty else{continue};let known=qs.filter{learning.knowledgeStates[$0.knowledgeID]?.masteryLevel == .known}.count;let mastery=Int((Double(known)/Double(qs.count)*100).rounded());guard mastery < g.masteryTarget else{continue}
     let days=max(1,g.deadline.map{Calendar.current.dateComponents([.day],from:date,to:$0).day ?? 1} ?? 30);let deficit=Double(g.masteryTarget-mastery)/100.0;let urgency=deficit/Double(days)
     cs.append(.init(course:c,goal:g,questions:qs,mastery:mastery,urgency:urgency))
   }}
   guard !cs.isEmpty else{return .init(date:date,budgetMinutes:budget,goals:[])}
   let total=max(0.0001,cs.reduce(0){$0+$1.urgency});var remaining=max(1,budget);var plans:[DailyStudyPlan.GoalPlan]=[]
   for (i,x) in cs.sorted(by:{$0.urgency>$1.urgency}).enumerated(){let mins=i==cs.count-1 ? remaining:max(5,Int((Double(budget)*x.urgency/total).rounded()));let allocated=min(remaining,mins);remaining-=allocated;let count=min(x.questions.count,max(1,allocated*2));let selected=adaptiveQuestions(goal:x.goal,materials:materials,learning:learning,count:count,date:date);plans.append(.init(id:x.goal.id,courseID:x.course.id,goalID:x.goal.id,title:x.goal.title,minutes:allocated,questions:selected,mastery:x.mastery,target:x.goal.masteryTarget,deadline:x.goal.deadline));if remaining<=0{break}}
   return .init(date:date,budgetMinutes:budget,goals:plans)
 }

 @MainActor private static func adaptiveQuestions(goal:LearningGoal,materials:MaterialStore,learning:LearningStore,count:Int,date:Date)->[StudyQuestion] {
   // Rank across all referenced sets: a due card in a later set must not
   // be displaced by a new/not-due card in an earlier set.
   let all=goal.questionSets.flatMap { ref -> [StudyQuestion] in
     guard let content=materials.content(id:ref.materialID) else{return []}
     return StudyQuestionBuilder.questions(for:ref,content:content)
   }
   var seen=Set<UUID>()
   let unique=all.filter { seen.insert($0.id).inserted }
   return Array(unique.sorted { lhs,rhs in
     let left=priority(lhs,learning,date:date),right=priority(rhs,learning,date:date)
     return left == right ? lhs.id.uuidString < rhs.id.uuidString : left > right
   }.prefix(count))
 }
 @MainActor private static func priority(_ q:StudyQuestion,_ l:LearningStore,date:Date)->Int { guard let s=l.knowledgeStates[q.knowledgeID] else{return 100};if s.nextDueAt <= date{return 80-s.streak*5};return 20-s.streak }
}

@MainActor enum GoalProgressService {
 static func reconcile(courses store:CourseStore,materials:MaterialStore,learning:LearningStore) {
  for original in store.courses { var course=original;var changed=false
   for i in course.goals.indices where course.goals[i].state == .active {
    let g=course.goals[i];let qs=g.questionSets.flatMap{ref -> [StudyQuestion] in guard let c=materials.content(id:ref.materialID) else{return []};return StudyQuestionBuilder.questions(for:ref,content:c)}
    guard !qs.isEmpty else{continue};let known=qs.filter{learning.knowledgeStates[$0.knowledgeID]?.masteryLevel == .known}.count;let mastery=Int((Double(known)/Double(qs.count)*100).rounded())
    if mastery >= g.masteryTarget { course.goals[i].state = .completed;changed=true }
   }
   if changed { store.save(course) }
  }
 }
}
