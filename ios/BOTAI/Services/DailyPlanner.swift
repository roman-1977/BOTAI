import Foundation

enum StudyQuestionSelection {
  // One representation per knowledge item and one response mode per session.
  static func uniqueKnowledge(_ questions: [StudyQuestion]) -> [StudyQuestion] {
    var seen = Set<UUID>()
    return questions.filter { seen.insert($0.knowledgeID).inserted }
  }
  enum Format { case mixed, cards, tests }
  enum Strategy { case automatic, all }

  static func select(_ questions: [StudyQuestion], format: Format = .mixed,
                     strategy: Strategy = .automatic,
                     knowledgeStates: [UUID: LearningState], now: Date) -> [StudyQuestion] {
    var seen = Set<UUID>()
    let eligible = questions.filter { question in
      guard seen.insert(question.id).inserted else { return false }
      switch format {
      case .mixed: return true
      case .cards: return question.kind == .reveal || question.kind == .pair
      case .tests: return question.kind == .singleChoice || question.kind == .multipleChoice
      }
    }
    guard strategy == .automatic else { return eligible }
    return eligible.sorted {
      priority($0, states: knowledgeStates, now: now) > priority($1, states: knowledgeStates, now: now)
    }
  }

  static func forSession(_ questions: [StudyQuestion], format: Format = .cards,
                         strategy: Strategy = .automatic,
                         knowledgeStates: [UUID: LearningState], now: Date) -> [StudyQuestion] {
    let eligible = uniqueKnowledge(select(questions, format: format, strategy: strategy,
                                         knowledgeStates: knowledgeStates, now: now))
    // Shuffle within priority tiers, not across them: weak/due before new,
    // new before not-due. This avoids the source table's adjacent acid rows.
    guard strategy == .automatic else { return eligible.shuffled() }
    let groups = Dictionary(grouping: eligible) { question in
      priorityTier(question, states: knowledgeStates, now: now)
    }
    return [2, 1, 0].flatMap { (groups[$0] ?? []).shuffled() }
  }

  private static func priorityTier(_ question: StudyQuestion, states: [UUID: LearningState], now: Date) -> Int {
    guard let state = states[question.knowledgeID] else { return 1 }
    return state.nextDueAt <= now ? 2 : 0
  }

  private static func priority(_ question: StudyQuestion, states: [UUID: LearningState], now: Date) -> Int {
    guard let state = states[question.knowledgeID] else { return 100 }
    if state.nextDueAt <= now { return 300 - min(max(state.streak, 0), 20) * 5 }
    return 30 - min(max(state.streak, 0), 20)
  }
}

enum DailyPlanner {
 @MainActor static func make(courses:[StudyCourse],materials:MaterialStore,learning:LearningStore,profile:StudyProfile,date:Date = .now)->DailyStudyPlan {
   let weekday=Calendar.current.component(.weekday,from:date),budget=profile.minutes(for:weekday)
   struct Candidate { let course:StudyCourse;let goal:LearningGoal;let questions:[StudyQuestion];let mastery:Int;let urgency:Double }
   var cs:[Candidate]=[]
   for c in courses { for g in c.goals where g.state == .active {
     let scopedRefs = stagedReferences(course: c, goal: g, materials: materials, states: learning.knowledgeStates)
     let qs=scopedRefs.flatMap{ref -> [StudyQuestion] in guard let content=materials.content(id:ref.materialID) else{return []};return StudyQuestionBuilder.questions(for:ref,content:content)}
     guard !qs.isEmpty else{continue}
    let mastery = GoalProgressService.masteryPercentage(questions: qs, states: learning.knowledgeStates);guard mastery < g.masteryTarget else{continue}
     let days=daysRemaining(deadline:g.deadline,now:date);let deficit=Double(g.masteryTarget-mastery)/100.0;let urgency=deficit/Double(days)
     cs.append(.init(course:c,goal:g,questions:qs,mastery:mastery,urgency:urgency))
   }}
   guard !cs.isEmpty else{return .init(date:date,budgetMinutes:budget,goals:[])}
   let ranked = cs.sorted {
    if $0.urgency != $1.urgency { return $0.urgency > $1.urgency }
    let a = guidanceRank($0.goal.guidance?.priority), b = guidanceRank($1.goal.guidance?.priority)
    if a != b { return a > b }
    return guidanceDifficultyRank($0.goal.guidance?.difficulty) > guidanceDifficultyRank($1.goal.guidance?.difficulty)
   }
   // Prepare unique question pools before assigning time. An overlapping goal
   // with no remaining unique work must not consume the shared daily budget.
   var scheduledQuestionIDs=Set<UUID>()
   var work:[(candidate:Candidate,questions:[StudyQuestion])]=[]
   for x in ranked {
    // Shuffle before limiting the daily quota so every eligible item can be reached.
    // Preserve the teacher's goal planning across all material types.
    // Automatic session launch filters to objectively graded tests separately.
    let ordered=StudyQuestionSelection.forSession(x.questions,format:.mixed,
       knowledgeStates:learning.knowledgeStates,now:date)
    let unique=takeUnique(ordered,count:ordered.count,seen:&scheduledQuestionIDs)
    if !unique.isEmpty { work.append((candidate:x,questions:unique)) }
   }
   let allocations=allocateMinutes(budget:budget,urgencies:work.map { $0.candidate.urgency })
   var plans:[DailyStudyPlan.GoalPlan]=[]
   for (i,item) in work.enumerated() {
    let x=item.candidate,allocated=allocations[i]
    if allocated == 0 && budget > 0 { continue }
    let count=min(item.questions.count,max(1,allocated*2))
    let selected=Array(item.questions.prefix(count))
    plans.append(.init(id:x.goal.id,courseID:x.course.id,goalID:x.goal.id,title:x.goal.title,minutes:allocated,questions:selected,mastery:x.mastery,target:x.goal.masteryTarget,deadline:x.goal.deadline))
   }
   return .init(date:date,budgetMinutes:budget,goals:plans)
 }

 /// Advance to the next teacher-ordered section only when the previous
 /// section has reached its explicitly configured unique-knowledge threshold.
 /// Once all staged sections pass, the whole goal becomes available for review.
 @MainActor static func stagedReferences(course: StudyCourse, goal: LearningGoal,
                                         materials: MaterialStore,
                                         states: [UUID: LearningState]) -> [CourseRuleReference] {
  guard let route=course.stagedLearning, (1...100).contains(route.threshold),
        !route.sectionIDs.isEmpty else { return goal.questionSets }
  let allowed=Set(goal.questionSets)
  for sectionID in route.sectionIDs {
   guard let section=course.sections.first(where: { $0.id == sectionID }) else { return goal.questionSets }
   let refs=section.topics.flatMap(\.questionSets).filter { allowed.contains($0) }
   let questions=refs.flatMap { ref -> [StudyQuestion] in
    guard let content=materials.content(id:ref.materialID) else { return [] }
    return StudyQuestionBuilder.questions(for:ref,content:content)
   }
   guard !questions.isEmpty else { return goal.questionSets }
   if GoalProgressService.masteryPercentage(questions: questions, states: states) < route.threshold {
    return refs
   }
  }
  return goal.questionSets
 }

 // Calendar-day deadlines must not lose a day because of the current clock
 // time. Overdue deadlines are urgent, not a negative allocation divisor.
 static func daysRemaining(deadline:Date?,now:Date,calendar:Calendar = .current)->Int {
  guard let deadline else { return 30 }
  let today=calendar.startOfDay(for:now)
  let end=calendar.startOfDay(for:deadline)
  return max(1,calendar.dateComponents([.day],from:today,to:end).day ?? 1)
 }

 // A shared questionnaire may be referenced by multiple goals. Do not schedule
 // the same question twice; fill the slot with the next eligible question.
 static func takeUnique(_ questions: [StudyQuestion], count: Int, seen: inout Set<UUID>) -> [StudyQuestion] {
  guard count > 0 else { return [] }
  var selected:[StudyQuestion]=[]
  for question in questions where seen.insert(question.id).inserted {
   selected.append(question)
   if selected.count == count { break }
  }
  return selected
 }

 // Guarantee each goal a share when the user has enough minutes. Remaining
 // minutes follow observed deadline/mastery urgency; ties preserve input order.
 // The total never exceeds the learner-owned daily budget.
 static func allocateMinutes(budget: Int, urgencies: [Double]) -> [Int] {
  guard !urgencies.isEmpty else { return [] }
  let available=max(0,budget)
  var result=Array(repeating:0,count:urgencies.count)
  let seeded=min(available,urgencies.count)
  for i in 0..<seeded { result[i]=1 }
  let remaining=available-seeded
  guard remaining>0 else { return result }
  let weights=urgencies.map { $0.isFinite ? max(0,$0) : 0 }
  let total=weights.reduce(0,+)
  guard total>0 else {
   for i in 0..<remaining { result[i % result.count]+=1 }
   return result
  }
  let exact=weights.map { Double(remaining)*$0/total }
  let floors=exact.map { Int($0.rounded(.down)) }
  for i in result.indices { result[i]+=floors[i] }
  let leftover=remaining-floors.reduce(0,+)
  let order=result.indices.sorted {
   let first=exact[$0]-Double(floors[$0]), second=exact[$1]-Double(floors[$1])
   return first == second ? $0<$1 : first>second
  }
  if leftover>0 { for i in 0..<leftover { result[order[i]]+=1 } }
  return result
 }

 // Teacher pace is advice, not permission to change the learner's profile.
 // Comparing against the *allocated* share keeps multi-goal feedback honest.
 enum PaceAssessment: Equatable {
  case notProvided, matched, belowSuggestion(minutes: Int), aboveSuggestion(minutes: Int)
 }
 static func assessPace(guidance: CourseLearningGuidance?, allocatedMinutes: Int) -> PaceAssessment {
  guard let suggested = guidance?.recommendedDailyMinutes, suggested > 0 else { return .notProvided }
  let delta = max(0,allocatedMinutes)-suggested
  if delta == 0 { return .matched }
  return delta < 0 ? .belowSuggestion(minutes: -delta) : .aboveSuggestion(minutes: delta)
 }

 // Recommendations break ties between equally urgent goals. Deadline and actual
 // mastery still lead, so teacher guidance never overrides student evidence.
 static func guidanceDifficultyRank(_ difficulty: Int?) -> Int {
  guard let difficulty, (1...5).contains(difficulty) else { return 0 }
  return difficulty
 }
 static func guidanceRank(_ priority: CourseLearningGuidance.Priority?) -> Int {
  switch priority { case .critical: return 2; case .elevated: return 1; case .standard, nil: return 0 }
 }

 @MainActor private static func adaptiveQuestions(goal:LearningGoal,materials:MaterialStore,learning:LearningStore,count:Int,date:Date,excluding seen:inout Set<UUID>)->[StudyQuestion] {
   // Rank across all referenced sets: a due card in a later set must not
   // be displaced by a new/not-due card in an earlier set.
   let all=goal.questionSets.flatMap { ref -> [StudyQuestion] in
     guard let content=materials.content(id:ref.materialID) else{return []}
     return StudyQuestionBuilder.questions(for:ref,content:content)
   }
   return takeUnique(StudyQuestionSelection.select(all, knowledgeStates: learning.knowledgeStates, now: date),count:count,seen:&seen)
 }
}

@MainActor enum GoalProgressService {
 static func masteryPercentage(questions: [StudyQuestion], states: [UUID: LearningState]) -> Int {
  let ids = Set(questions.map(\.knowledgeID))
  guard !ids.isEmpty else { return 0 }
  let known = ids.filter { states[$0]?.masteryLevel == .known }.count
  return Int((Double(known) / Double(ids.count) * 100).rounded())
 }
 static func reconcile(courses store:CourseStore,materials:MaterialStore,learning:LearningStore) {
  for original in store.courses { var course=original;var changed=false
   for i in course.goals.indices where course.goals[i].state == .active {
    let g=course.goals[i];let qs=g.questionSets.flatMap{ref -> [StudyQuestion] in guard let c=materials.content(id:ref.materialID) else{return []};return StudyQuestionBuilder.questions(for:ref,content:c)}
    guard !qs.isEmpty else{continue}
    let mastery = masteryPercentage(questions: qs, states: learning.knowledgeStates)
    if mastery >= g.masteryTarget { course.goals[i].state = .completed;changed=true }
   }
   if changed { store.save(course) }
  }
 }
}
