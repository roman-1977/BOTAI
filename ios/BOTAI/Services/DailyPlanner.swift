import Foundation

enum DailyPlanner {
 @MainActor static func make(courses:[StudyCourse],materials:MaterialStore,learning:LearningStore,profile:StudyProfile,date:Date = .now)->DailyStudyPlan {
   let weekday=Calendar.current.component(.weekday,from:date),budget=profile.minutes(for:weekday)
   struct Candidate { let course:StudyCourse;let goal:LearningGoal;let questions:[StudyQuestion];let mastery:Int;let urgency:Double }
   var cs:[Candidate]=[]
   for c in courses { for g in c.goals where g.state == .active {
     let qs=g.questionSets.flatMap{ref -> [StudyQuestion] in guard let content=materials.content(id:ref.materialID) else{return []};return StudyQuestionBuilder.questions(for:ref,content:content)}
     guard !qs.isEmpty else{continue};let known=qs.filter{learning.states[$0.id]?.masteryLevel == .known}.count;let mastery=Int((Double(known)/Double(qs.count)*100).rounded());guard mastery < g.masteryTarget else{continue}
     let days=max(1,g.deadline.map{Calendar.current.dateComponents([.day],from:date,to:$0).day ?? 1} ?? 30);let deficit=Double(g.masteryTarget-mastery)/100.0;let urgency=deficit/Double(days)
     cs.append(.init(course:c,goal:g,questions:qs,mastery:mastery,urgency:urgency))
   }}
   guard !cs.isEmpty,budget>0 else{return .init(date:date,budgetMinutes:budget,goals:[])}
   let total=max(0.0001,cs.reduce(0){$0+$1.urgency});var remaining=budget;var plans:[DailyStudyPlan.GoalPlan]=[]
   for (i,x) in cs.sorted(by:{$0.urgency>$1.urgency}).enumerated(){let mins=i==cs.count-1 ? remaining:max(5,Int((Double(budget)*x.urgency/total).rounded()));let allocated=min(remaining,mins);remaining-=allocated;let count=min(x.questions.count,max(1,allocated*2));let selected=adaptiveQuestions(goal:x.goal,materials:materials,learning:learning,count:count);plans.append(.init(id:x.goal.id,courseID:x.course.id,goalID:x.goal.id,title:x.goal.title,minutes:allocated,questions:selected,mastery:x.mastery,target:x.goal.masteryTarget,deadline:x.goal.deadline));if remaining<=0{break}}
   return .init(date:date,budgetMinutes:budget,goals:plans)
 }

 @MainActor private static func adaptiveQuestions(goal:LearningGoal,materials:MaterialStore,learning:LearningStore,count:Int)->[StudyQuestion] {
   var groups=goal.questionSets.compactMap{ref -> [StudyQuestion]? in guard let c=materials.content(id:ref.materialID) else{return nil};let qs=StudyQuestionBuilder.questions(for:ref,content:c).shuffled().sorted{priority($0,learning)>priority($1,learning)};return qs.isEmpty ? nil:qs}
   groups.shuffle();var result:[StudyQuestion]=[];var cursor=0
   while result.count<count && groups.contains(where:{!$0.isEmpty}) { let i=cursor % groups.count;if !groups[i].isEmpty { result.append(groups[i].removeFirst()) };cursor += 1 }
   return result
 }
 @MainActor private static func priority(_ q:StudyQuestion,_ l:LearningStore)->Int { guard let s=l.states[q.id] else{return 100};if s.nextDueAt <= .now{return 80-s.streak*5};return 20-s.streak }
}

@MainActor enum GoalProgressService {
 static func reconcile(courses store:CourseStore,materials:MaterialStore,learning:LearningStore) {
  for original in store.courses { var course=original;var changed=false
   for i in course.goals.indices where course.goals[i].state == .active {
    let g=course.goals[i];let qs=g.questionSets.flatMap{ref -> [StudyQuestion] in guard let c=materials.content(id:ref.materialID) else{return []};return StudyQuestionBuilder.questions(for:ref,content:c)}
    guard !qs.isEmpty else{continue};let known=qs.filter{learning.states[$0.id]?.masteryLevel == .known}.count;let mastery=Int((Double(known)/Double(qs.count)*100).rounded())
    if mastery >= g.masteryTarget { course.goals[i].state = .completed;changed=true }
   }
   if changed { store.save(course) }
  }
 }
}
