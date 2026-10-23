import Foundation
import PDFKit
import Testing
@testable import BOTAI

@MainActor struct SharedGoalMasteryTests {
    @Test func repeatedKnowledgeDoesNotInflateGoalCompletion() {
        let shared = UUID(), other = UUID()
        let first = StudyQuestion(id: UUID(), prompt: "Shared A", answer: "A", kind: .reveal,
            choices: [], correctChoiceIndexes: [], knowledgeID: shared)
        let reused = StudyQuestion(id: UUID(), prompt: "Shared B", answer: "A", kind: .pair,
            choices: [], correctChoiceIndexes: [], knowledgeID: shared)
        let distinct = StudyQuestion(id: UUID(), prompt: "Other", answer: "B", kind: .reveal,
            choices: [], correctChoiceIndexes: [], knowledgeID: other)
        let known = LearningState(intervalDays: 10, streak: 5, nextDueAt: .now)
        #expect(GoalProgressService.masteryPercentage(questions: [first, reused, distinct],
            states: [shared: known]) == 50)
        #expect(GoalProgressService.masteryPercentage(questions: [first, reused],
            states: [shared: known]) == 100)
        #expect(GoalProgressService.masteryPercentage(questions: [], states: [shared: known]) == 0)
    }
}

struct DailyPlanTests {
    @Test func progressIsCappedAtOne() {
        let plan = DailyPlan(completed: 12, recommended: 10, habitMinimum: 5, due: 0, weak: 0, new: 0)
        #expect(plan.progress == 1)
    }

    @Test func habitMinimumIsIndependentFromFullPlan() {
        let plan = DailyPlan(completed: 5, recommended: 18, habitMinimum: 5, due: 8, weak: 6, new: 4)
        #expect(plan.isHabitMinimumComplete)
        #expect(plan.progress < 1)
    }
}

@MainActor struct RestDayAndPDFReportTests {
    @Test @MainActor func zeroScheduledMinutesDoesNotBlockVoluntaryLearning() throws {
        let database = try AppDatabase()
        let materialID = UUID(), ruleID = UUID(), rowID = UUID()
        let material = StudyMaterialRecord(id: materialID, title: "Chemistry", subject: "Химия", topic: "Кислоты",
            kind: .quiz, source: .created, createdAt: .now, updatedAt: .now)
        let row = KnowledgeRow(id: rowID, materialID: materialID, position: 0, values: ["q":"HCl?", "a":"Соляная"])
        let rule = QuestionRule(id: ruleID, materialID: materialID, kind: .card,
            promptFieldKey: "q", answerFieldKey: "a", promptFieldKeys: ["q"],
            answers: [.init(template:"{1}",fieldKeys:["a"],correct:true)], enabled:true)
        try MaterialRepository(database: database).save(material: material, fields: [], rows: [row], rules: [rule])
        let ref = CourseRuleReference(materialID:materialID,ruleID:ruleID)
        let goal = LearningGoal(id:UUID(),title:"Learn chemistry",questionSets:[ref],masteryTarget:90,deadline:nil,state:.active)
        let course = StudyCourse(id:UUID(),title:"Chemistry",description:"",subject:"Химия",audience:"ЕГЭ",
            estimatedMinutes:nil,author:nil,language:"ru",coverSymbol:"book",source:.created,sections:[],goals:[goal],createdAt:.now,updatedAt:.now)
        let profile = StudyProfile(defaultDailyMinutes:0,customDays:[],updatedAt:.now)
        let plan = DailyPlanner.make(courses:[course],materials:MaterialStore(repository:MaterialRepository(database:database)),
            learning:LearningStore(questions:[],repository:LearningRepository(database:database)),profile:profile)
        #expect(plan.budgetMinutes == 0)
        #expect(plan.plannedMinutes == 0) // Rest day is not silently converted into mandatory study time
        #expect(plan.questions.count == 1)
        #expect(plan.goals.count == 1)
        let secondPlan = DailyPlanner.make(courses:[course],materials:MaterialStore(repository:MaterialRepository(database:database)),
            learning:LearningStore(questions:[],repository:LearningRepository(database:database)),profile:profile,
            date:plan.date)
        #expect(plan.questions.map(\.id) == secondPlan.questions.map(\.id))
    }

    @Test func extendedReportProducesNonemptyPDFOnRestDays() throws {
        let profile = StudyProfile(defaultDailyMinutes:0,customDays:[],updatedAt:.now)
        let url = try StudyPDFReport.export(profile:profile,sessions:[],attempts:[],knowledgeStates:[:],courses:[])
        defer { try? FileManager.default.removeItem(at:url) }
        let data = try Data(contentsOf:url)
        #expect(data.starts(with:Data("%PDF".utf8)))
        #expect(data.count > 1500)
    }
}


@MainActor struct ForecastRecommendationPDFTests {
    @Test func underPlanSuggestsMorePractice() throws {
        let profile = StudyProfile(defaultDailyMinutes:30,customDays:[],updatedAt:.now)
        let url = try StudyPDFReport.export(profile:profile,sessions:[],attempts:[],knowledgeStates:[:],courses:[])
        defer { try? FileManager.default.removeItem(at:url) }
        let text = try #require(PDFDocument(url:url)?.string)
        #expect(text.contains("отставание от плана"))
        #expect(text.contains("Рекомендация: добавить"))
    }

    @Test func aheadOfPlanDoesNotRecommendIncreasingWorkload() throws {
        let now = Date()
        let profile = StudyProfile(defaultDailyMinutes:10,customDays:[],updatedAt:now)
        let sessions = (0..<14).map { offset in
            let date = Calendar.current.date(byAdding:.day,value:-offset,to:now)!
            return StudySession(id:UUID(),startedAt:date,endedAt:date.addingTimeInterval(1200),activeSeconds:1200,answered:5,correct:4)
        }
        let url = try StudyPDFReport.export(profile:profile,sessions:sessions,attempts:[],knowledgeStates:[:],courses:[],now:now)
        defer { try? FileManager.default.removeItem(at:url) }
        let text = try #require(PDFDocument(url:url)?.string)
        #expect(text.contains("опережение плана"))
        #expect(text.contains("дополнительные занятия необязательны"))
    }
}

struct KnowledgeDeadlineForecastTests {
    private func goal(deadline: Date? = nil, target: Int = 90) -> LearningGoal {
        LearningGoal(id: UUID(), title: "Химия", questionSets: [], masteryTarget: target, deadline: deadline, state: .active)
    }
    private func event(_ knowledge: UUID, daysAgo: Int, known: Bool, now: Date) -> LearningRepository.KnowledgeProgressEvent {
        .init(attemptID: UUID(), knowledgeID: knowledge,
              occurredAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!, isKnown: known)
    }
    @Test func sharedQuestionCountsInEachTopicButOnlyOnceForCombinedGoal() {
        let now = Date()
        let shared = UUID(), firstOnly = UUID(), secondOnly = UUID()
        // Two topics reuse one questionnaire. Their own coverage includes the shared
        // knowledge, while the subject-wide goal takes a union, not a sum.
        let firstTopic: Set<UUID> = [shared, firstOnly]
        let secondTopic: Set<UUID> = [shared, secondOnly]
        let combined = firstTopic.union(secondTopic)
        let known = LearningState(intervalDays: 7, streak: 5, nextDueAt: now)
        let states = [shared: known]
        let full = goal(target: 100)
        let first = KnowledgeDeadlineForecast.evaluate(goal: full, knowledgeIDs: firstTopic,
            states: states, history: [], now: now)
        let second = KnowledgeDeadlineForecast.evaluate(goal: full, knowledgeIDs: secondTopic,
            states: states, history: [], now: now)
        let subject = KnowledgeDeadlineForecast.evaluate(goal: full, knowledgeIDs: combined,
            states: states, history: [], now: now)
        #expect(first.currentKnown == 1 && second.currentKnown == 1)
        #expect(first.requiredKnown == 2 && second.requiredKnown == 2)
        #expect(subject.currentKnown == 1)
        #expect(subject.requiredKnown == 3)
        #expect(subject.remaining == 2)
    }

    @Test func insufficientHistoryDoesNotInventDeadlineForecast() {
        let now = Date()
        let ids = Set((0..<10).map { _ in UUID() })
        let result = KnowledgeDeadlineForecast.evaluate(goal: goal(deadline: now.addingTimeInterval(86400 * 20)),
            knowledgeIDs: ids, states: [:], history: [], now: now)
        #expect(result.estimatedCompletion == nil)
        #expect(result.remaining == 9)
        #expect(result.reportLines.joined().contains("Недостаточно истории"))
    }
    @Test func positiveMasteryGrowthPredictsAheadOfDeadline() {
        let now = Date()
        let ids = (0..<10).map { _ in UUID() }
        let states = Dictionary(uniqueKeysWithValues: ids.prefix(3).map { ($0, LearningState(intervalDays: 20, streak: 5, nextDueAt: now)) })
        let history = [event(ids[0],daysAgo: 10,known: false,now: now),
                       event(ids[0],daysAgo: 8,known: true,now: now),
                       event(ids[1],daysAgo: 5,known: true,now: now),
                       event(ids[2],daysAgo: 0,known: true,now: now)]
        let result = KnowledgeDeadlineForecast.evaluate(goal: goal(deadline: now.addingTimeInterval(86400 * 60)),
            knowledgeIDs: Set(ids), states: states, history: history, now: now)
        #expect(result.estimatedCompletion != nil)
        #expect(result.observedPerDay != nil)
        #expect(result.reportLines.joined().contains("опережение срока"))
    }
    @Test func slowMasteryGrowthRecommendsIncreasingPractice() {
        let now = Date()
        let ids = (0..<30).map { _ in UUID() }
        let history = [event(ids[0],daysAgo: 10,known: false,now: now),
                       event(ids[0],daysAgo: 5,known: false,now: now),
                       event(ids[0],daysAgo: 0,known: true,now: now)]
        let result = KnowledgeDeadlineForecast.evaluate(goal: goal(deadline: now.addingTimeInterval(86400 * 7)),
            knowledgeIDs: Set(ids), states: [:], history: history, now: now)
        #expect(result.reportLines.joined().contains("отставание от срока"))
        #expect(result.reportLines.joined().contains("увеличить частоту"))
    }
    @Test func noObservedGrowthReturnsNoEta() {
        let now = Date()
        let id = UUID()
        let result = KnowledgeDeadlineForecast.evaluate(goal: goal(deadline: now.addingTimeInterval(86400 * 20)),
            knowledgeIDs: [id, UUID()], states: [:],
            history: [event(id,daysAgo: 6,known: false,now: now),event(id,daysAgo: 3,known: false,now: now),event(id,daysAgo: 0,known: false,now: now)], now: now)
        #expect(result.estimatedCompletion == nil)
        #expect(result.reportLines.joined().contains("Устойчивого прироста"))
    }
}

extension KnowledgeDeadlineForecastTests {
    @Test func oldActivityOutsideRollingWindowDoesNotProduceFalseEta() {
        let now = Date()
        let id = UUID()
        let events = [event(id,daysAgo: 120,known: false,now: now),
                      event(id,daysAgo: 90,known: true,now: now),
                      event(id,daysAgo: 60,known: true,now: now)]
        let result = KnowledgeDeadlineForecast.evaluate(goal: goal(deadline: now.addingTimeInterval(86400 * 30)),
            knowledgeIDs: [id,UUID()], states: [:], history: events, now: now)
        #expect(result.estimatedCompletion == nil)
        #expect(result.reportLines.joined().contains("Недостаточно истории"))
    }
    @Test func masteryRegressionPreventsOptimisticEta() {
        let now = Date()
        let id = UUID()
        let events = [event(id,daysAgo: 10,known: true,now: now),
                      event(id,daysAgo: 5,known: false,now: now),
                      event(id,daysAgo: 0,known: false,now: now)]
        let result = KnowledgeDeadlineForecast.evaluate(goal: goal(deadline: now.addingTimeInterval(86400 * 30)),
            knowledgeIDs: [id,UUID()], states: [:], history: events, now: now)
        #expect(result.estimatedCompletion == nil)
        #expect(result.observedPerDay ?? 1 <= 0)
    }
}

@MainActor struct ForecastChartPDFTests {
  @Test func historyAddsChartPageWithReadableText() throws {
    let goalID = UUID()
    let now = Date()
    let first = LearningRepository.ForecastSnapshot(goalID:goalID,day:"2026-10-19",calculatedAt:now.addingTimeInterval(-86400 * 3),forecastAt:nil,known:2,target:10,rate:0.1,algorithmVersion:2)
    let last = LearningRepository.ForecastSnapshot(goalID:goalID,day:"2026-10-22",calculatedAt:now,forecastAt:nil,known:5,target:10,rate:0.3,algorithmVersion:2)
    let profile = StudyProfile(defaultDailyMinutes:30,customDays:[],updatedAt:now)
    let url = try StudyPDFReport.export(profile:profile,sessions:[],attempts:[],knowledgeStates:[:],courses:[],forecastHistory:[first,last],now:now)
    defer { try? FileManager.default.removeItem(at:url) }
    let pdf = try #require(PDFDocument(url:url))
    #expect(pdf.pageCount >= 2)
    #expect(pdf.string?.contains("ИСТОРИЯ ПРОГНОЗОВ") == true)
    #expect(pdf.string?.contains("освоено 2 → 5") == true)
  }

  @Test func noHistoryDoesNotAddEmptyChartPage() throws {
    let url = try StudyPDFReport.export(profile:.standard,sessions:[],attempts:[],knowledgeStates:[:],courses:[])
    defer { try? FileManager.default.removeItem(at:url) }
    let pdf = try #require(PDFDocument(url:url))
    #expect(pdf.string?.contains("ИСТОРИЯ ПРОГНОЗОВ") == false)
  }
}

extension ForecastChartPDFTests {
  @Test func deadlineTrendHasReadableLabels() throws {
    let now = Date(), id = UUID()
    let goal = LearningGoal(id:id,title:"Физика",questionSets:[],masteryTarget:90,
      deadline:now.addingTimeInterval(86400 * 20),state:.active)
    let course = StudyCourse(id:UUID(),title:"Курс",description:"",subject:"Физика",audience:"ЕГЭ",
      estimatedMinutes:nil,author:nil,language:"ru",coverSymbol:"book",source:.created,
      sections:[],goals:[goal],createdAt:now,updatedAt:now)
    let history = [
      LearningRepository.ForecastSnapshot(goalID:id,day:"2026-10-19",calculatedAt:now.addingTimeInterval(-259200),
        forecastAt:now.addingTimeInterval(86400 * 25),known:2,target:10,rate:0.1,algorithmVersion:2),
      LearningRepository.ForecastSnapshot(goalID:id,day:"2026-10-22",calculatedAt:now,
        forecastAt:now.addingTimeInterval(86400 * 18),known:5,target:10,rate:0.3,algorithmVersion:2)
    ]
    let url = try StudyPDFReport.export(profile:.standard,sessions:[],attempts:[],knowledgeStates:[:],
      courses:[course],forecastHistory:history,now:now)
    defer { try? FileManager.default.removeItem(at:url) }
    let pdf = try #require(PDFDocument(url:url))
    #expect(pdf.string?.contains("Прогноз относительно") == true)
    #expect(pdf.string?.contains("Первый:") == true)
    #expect(pdf.string?.contains("последний:") == true)
  }
}

extension ForecastChartPDFTests {
  @Test func manyGoalsLongHistoryFitWithinPageBounds() throws {
    let now = Date()
    let goals = (0..<8).map { index in
      LearningGoal(id: UUID(), title: "Цель №\(index)", questionSets: [],
        masteryTarget: 90, deadline: now.addingTimeInterval(86400 * 30), state: .active)
    }
    let course = StudyCourse(id: UUID(), title: "Курс", description: "", subject: "Физика",
      audience: "ЕГЭ", estimatedMinutes: nil, author: nil, language: "ru",
      coverSymbol: "book", source: .created, sections: [], goals: goals,
      createdAt: now, updatedAt: now)
    var snapshots: [LearningRepository.ForecastSnapshot] = []
    for goal in goals {
      for index in 0..<60 {
        let observedAt = now.addingTimeInterval(Double(index - 59) * 86400)
        let predictedAt = now.addingTimeInterval(Double(50 - index / 2) * 86400)
        let item = LearningRepository.ForecastSnapshot(goalID: goal.id, day: "day-\(index)",
          calculatedAt: observedAt, forecastAt: predictedAt,
          known: index, target: 60, rate: 0.4, algorithmVersion: 2)
        snapshots.append(item)
      }
    }
    let url = try StudyPDFReport.export(profile: .standard, sessions: [], attempts: [],
      knowledgeStates: [:], courses: [course], forecastHistory: snapshots, now: now)
    defer { try? FileManager.default.removeItem(at: url) }
    let pdf = try #require(PDFDocument(url: url))
    #expect(pdf.pageCount >= 4)
    let allText = pdf.string ?? ""
    for index in 0..<8 { #expect(allText.contains("Цель №\(index)")) }
    for pageIndex in 0..<pdf.pageCount {
      guard let page = pdf.page(at: pageIndex) else { continue }
      let pageBounds = page.bounds(for: .mediaBox)
      for selection in (page.selection(for: pageBounds)?.selectionsByLine() ?? []) {
        let bounds = selection.bounds(for: page)
        #expect(bounds.minX >= -2)
        #expect(bounds.minY >= -2)
        #expect(bounds.maxX <= pageBounds.maxX + 2)
        #expect(bounds.maxY <= pageBounds.maxY + 2)
      }
    }
  }
}

struct StudyQuestionSelectionMatrixTests {
    private func question(_ kind: StudyQuestion.Kind, _ id: UUID = UUID()) -> StudyQuestion {
        StudyQuestion(id: id, prompt: "Prompt", answer: "Answer", kind: kind,
                      choices: [], correctChoiceIndexes: [])
    }

    @Test func formatMatrixAndDuplicateQuestionIDs() {
        let questions = [question(.reveal), question(.pair), question(.singleChoice), question(.multipleChoice)]
        for (format, expected) in [
            (StudyQuestionSelection.Format.mixed, 4), (.cards, 2), (.tests, 2)
        ] {
            let result = StudyQuestionSelection.select(questions + [questions[0]], format: format,
                strategy: .all, knowledgeStates: [:], now: .now)
            #expect(result.count == expected)
            #expect(Set(result.map(\.id)).count == result.count)
        }
        #expect(StudyQuestionSelection.select(questions, format: .cards,
            knowledgeStates: [:], now: .now).map(\.kind) == [.reveal, .pair])
        #expect(StudyQuestionSelection.select(questions, format: .tests,
            knowledgeStates: [:], now: .now).map(\.kind) == [.singleChoice, .multipleChoice])
    }

    @Test func allFormatsAndStrategiesPreserveUniqueQuestionIdentity() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let questions = [question(.reveal), question(.pair),
                         question(.singleChoice), question(.multipleChoice)]
        let source = questions + questions + [questions[1]]
        for strategy in [StudyQuestionSelection.Strategy.automatic, .all] {
            for (format, expectedKinds) in [
                (StudyQuestionSelection.Format.mixed,
                    [StudyQuestion.Kind.reveal, .pair, .singleChoice, .multipleChoice]),
                (.cards, [.reveal, .pair]),
                (.tests, [.singleChoice, .multipleChoice])
            ] {
                let selected = StudyQuestionSelection.select(source, format: format,
                    strategy: strategy, knowledgeStates: [:], now: now)
                #expect(selected.count == expectedKinds.count)
                #expect(Set(selected.map(\.id)).count == selected.count)
                #expect(Set(selected.map(\.kind)) == Set(expectedKinds))
            }
        }
    }

    @MainActor @Test func sharedKnowledgeAcrossFormatsUsesOneMasteryState() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let shared = UUID()
        let card = StudyQuestion(id: UUID(), prompt: "Card", answer: "A", kind: .reveal,
            choices: [], correctChoiceIndexes: [], knowledgeID: shared)
        let choice = StudyQuestion(id: UUID(), prompt: "Choice", answer: "A", kind: .singleChoice,
            choices: [], correctChoiceIndexes: [], knowledgeID: shared)
        let fresh = question(.pair)
        let source = [fresh, choice, card]
        let due = [shared: LearningState(intervalDays: 3, streak: 1, nextDueAt: now)]
        #expect(StudyQuestionSelection.select(source, knowledgeStates: due, now: now).map(\.id)
            == [choice.id, card.id, fresh.id])
        #expect(StudyQuestionSelection.select(source, format: .cards,
            knowledgeStates: due, now: now).map(\.id) == [card.id, fresh.id])
        #expect(StudyQuestionSelection.select(source, format: .tests,
            knowledgeStates: due, now: now).map(\.id) == [choice.id])
        #expect(GoalProgressService.masteryPercentage(questions: source,
            states: [shared: LearningState(intervalDays: 4, streak: 5, nextDueAt: now)]) == 50)
    }

    @Test func dueWeakThenNewThenNotDueWithStableTies() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let future = now.addingTimeInterval(86400)
        let dueStrong = question(.reveal), newA = question(.pair), futureCard = question(.singleChoice)
        let dueWeak = question(.multipleChoice), newB = question(.reveal)
        let source = [futureCard, newA, dueStrong, newB, dueWeak]
        let states: [UUID: LearningState] = [
            dueStrong.knowledgeID: LearningState(intervalDays: 3, streak: 4, nextDueAt: now),
            dueWeak.knowledgeID: LearningState(intervalDays: 0, streak: 0, nextDueAt: now),
            futureCard.knowledgeID: LearningState(intervalDays: 7, streak: 3, nextDueAt: future)
        ]
        let selected = StudyQuestionSelection.select(source, knowledgeStates: states, now: now)
        #expect(selected.map(\.id) == [dueWeak.id, dueStrong.id, newA.id, newB.id, futureCard.id])
        #expect(StudyQuestionSelection.select(source, strategy: .all,
            knowledgeStates: states, now: now).map(\.id) == source.map(\.id))
        #expect(StudyQuestionSelection.select([newA, newB], knowledgeStates: [:], now: now)
            .map(\.id) == [newA.id, newB.id])
        #expect(StudyQuestionSelection.select([], knowledgeStates: [:], now: now).isEmpty)
    }
}

struct CourseGuidanceCompatibilityTests {
 @Test func legacyGoalAndImportedGuidanceRoundTrip() throws {
  let legacy = LearningGoal(id: UUID(), title: "Химия", questionSets: [], masteryTarget: 90, deadline: nil, state: .active)
  let legacyDecoded = try JSONDecoder().decode(LearningGoal.self, from: JSONEncoder().encode(legacy))
  #expect(legacyDecoded.guidance == nil)
  let guided = LearningGoal(id: UUID(), title: "Химия", questionSets: [], masteryTarget: 90, deadline: nil, state: .active,
    guidance: CourseLearningGuidance(priority: .elevated, rationale: "Важная тема"))
  let restored = try JSONDecoder().decode(LearningGoal.self, from: JSONEncoder().encode(guided))
  #expect(restored.guidance == guided.guidance)
 }
}

struct TeacherGuidanceOrderingTests {
 @Test func difficultyIsOnlyAnOrdinalTieBreaker() {
  #expect(DailyPlanner.guidanceDifficultyRank(nil) == 0)
  #expect(DailyPlanner.guidanceDifficultyRank(9) == 0)
  #expect(DailyPlanner.guidanceDifficultyRank(5) > DailyPlanner.guidanceDifficultyRank(2))
 }
 @Test func prioritiesAreOrderedWithoutChangingLegacyDefault() {
  #expect(DailyPlanner.guidanceRank(nil) == DailyPlanner.guidanceRank(.standard))
  #expect(DailyPlanner.guidanceRank(.critical) > DailyPlanner.guidanceRank(.elevated))
  #expect(DailyPlanner.guidanceRank(.elevated) > DailyPlanner.guidanceRank(.standard))
 }
}

@MainActor struct TeacherDifficultyPlanIntegrationTests {
 @Test func difficultyBreaksEqualUrgencyWithoutOverridingTeacherPriorityOrBudget() throws {
  let database = try AppDatabase()
  let materialID = UUID(), ruleID = UUID()
  let material = StudyMaterialRecord(id:materialID,title:"Chemistry",subject:"Химия",topic:nil,kind:.quiz,source:.created,createdAt:.now,updatedAt:.now)
  let rows = (0..<3).map { KnowledgeRow(id:UUID(),materialID:materialID,position:$0,values:["q":"Q\($0)","a":"A\($0)"]) }
  let rule = QuestionRule(id:ruleID,materialID:materialID,kind:.card,promptFieldKey:"q",answerFieldKey:"a",promptFieldKeys:["q"],answers:[.init(template:"{1}",fieldKeys:["a"],correct:true)],enabled:true)
  try MaterialRepository(database:database).save(material:material,fields:[],rows:rows,rules:[rule])
  let ref = CourseRuleReference(materialID:materialID,ruleID:ruleID)
  let low = LearningGoal(id:UUID(),title:"Easy",questionSets:[ref],masteryTarget:90,deadline:nil,state:.active,guidance:.init(priority:.standard,difficulty:1))
  let high = LearningGoal(id:UUID(),title:"Hard",questionSets:[ref],masteryTarget:90,deadline:nil,state:.active,guidance:.init(priority:.standard,difficulty:5))
  let course = StudyCourse(id:UUID(),title:"Course",description:"",subject:"Химия",audience:"",estimatedMinutes:nil,author:nil,language:"ru",coverSymbol:"book",source:.created,sections:[],goals:[low,high],createdAt:.now,updatedAt:.now)
  let materials = MaterialStore(repository:MaterialRepository(database:database))
  let learning = LearningStore(questions:[],repository:LearningRepository(database:database))
  let profile = StudyProfile(defaultDailyMinutes:10,customDays:[],updatedAt:.now)
  let plan = DailyPlanner.make(courses:[course],materials:materials,learning:learning,profile:profile)
  #expect(plan.goals.count == 1) // same questionnaire is scheduled once
  #expect(plan.goals.first?.title == "Hard")
  #expect(plan.plannedMinutes <= plan.budgetMinutes)
  var promoted = course
  promoted.goals[0].guidance = .init(priority:.critical,difficulty:1)
  let priorityPlan = DailyPlanner.make(courses:[promoted],materials:materials,learning:learning,profile:profile)
  #expect(priorityPlan.goals.first?.title == "Easy")
 }
}

struct MultiGoalMinuteAllocationTests {
 @Test func allGoalsGetTimeWhenBudgetAllows() {
  #expect(DailyPlanner.allocateMinutes(budget: 3, urgencies: [0.8,0.1,0.1]) == [1,1,1])
  let result=DailyPlanner.allocateMinutes(budget: 12, urgencies: [0.8,0.1,0.1])
  #expect(result.reduce(0,+) == 12)
  #expect(result.allSatisfy { $0 >= 1 })
  #expect(result[0] > result[1])
 }
 @Test func budgetBelowGoalCountAndRestDayAreSafe() {
  #expect(DailyPlanner.allocateMinutes(budget: 2, urgencies: [1,1,1]) == [1,1,0])
  #expect(DailyPlanner.allocateMinutes(budget: 0, urgencies: [1,1,1]) == [0,0,0])
  #expect(DailyPlanner.allocateMinutes(budget: 5, urgencies: []) == [])
 }
 @Test func equalUrgencyAllocationIsDeterministic() {
  let a=DailyPlanner.allocateMinutes(budget: 11, urgencies: [1,1,1])
  #expect(a == DailyPlanner.allocateMinutes(budget: 11, urgencies: [1,1,1]))
  #expect(a.reduce(0,+) == 11)
  #expect(a.max()! - a.min()! <= 1)
 }
}

struct TeacherGuidanceMetadataTests {
 @Test func difficultyAndSuggestedPaceRoundTrip() throws {
  let guidance=CourseLearningGuidance(priority:.critical,rationale:"Повторить",difficulty:4,recommendedDailyMinutes:25)
  let restored=try JSONDecoder().decode(CourseLearningGuidance.self,from:JSONEncoder().encode(guidance))
  #expect(restored == guidance)
 }
 @Test func invalidRecommendationsNeverIncreaseStudyBudget() throws {
  let raw=Data(#"{"priority":"elevated","difficulty":9,"recommendedDailyMinutes":900}"#.utf8)
  let decoded=try JSONDecoder().decode(CourseLearningGuidance.self,from:raw)
  #expect(decoded.difficulty == nil)
  #expect(decoded.recommendedDailyMinutes == nil)
  let legacy=try JSONDecoder().decode(CourseLearningGuidance.self,from:Data(#"{"priority":"standard"}"#.utf8))
  #expect(legacy.difficulty == nil && legacy.recommendedDailyMinutes == nil)
 }
}

struct TeacherPaceAssessmentTests {
 @Test func comparesAdviceWithAllocatedShareWithoutOverridingBudget() {
  let advice=CourseLearningGuidance(priority:.elevated,recommendedDailyMinutes:25)
  #expect(DailyPlanner.assessPace(guidance:advice,allocatedMinutes:15) == .belowSuggestion(minutes:10))
  #expect(DailyPlanner.assessPace(guidance:advice,allocatedMinutes:25) == .matched)
  #expect(DailyPlanner.assessPace(guidance:advice,allocatedMinutes:30) == .aboveSuggestion(minutes:5))
  #expect(DailyPlanner.assessPace(guidance:advice,allocatedMinutes:0) == .belowSuggestion(minutes:25))
  #expect(DailyPlanner.assessPace(guidance:nil,allocatedMinutes:20) == .notProvided)
 }
}

struct CrossGoalQuestionDedupTests {
 @Test func repeatedQuestionsAreOnlyScheduledOnceAcrossGoals() {
  let shared=StudyQuestion(id:UUID(),prompt:"Shared",answer:"A",kind:.reveal,choices:[],correctChoiceIndexes:[],knowledgeID:UUID())
  let extra=StudyQuestion(id:UUID(),prompt:"Extra",answer:"B",kind:.reveal,choices:[],correctChoiceIndexes:[],knowledgeID:UUID())
  var seen=Set<UUID>()
  let first=DailyPlanner.takeUnique([shared],count:1,seen:&seen)
  let second=DailyPlanner.takeUnique([shared,extra],count:1,seen:&seen)
  #expect(first.map(\.id) == [shared.id])
  #expect(second.map(\.id) == [extra.id])
  #expect(seen.count == 2)
 }
}

struct CalendarDeadlinePlannerTests {
 @Test func sameAndNextCalendarDayAreNotTruncatedByTimeOfDay() throws {
  var calendar=Calendar(identifier:.gregorian)
  calendar.timeZone=try #require(TimeZone(secondsFromGMT:0))
  let now=try #require(calendar.date(from:DateComponents(year:2026,month:10,day:23,hour:23,minute:50)))
  let next=try #require(calendar.date(from:DateComponents(year:2026,month:10,day:24,hour:0,minute:5)))
  let later=try #require(calendar.date(from:DateComponents(year:2026,month:10,day:26,hour:0,minute:5)))
  #expect(DailyPlanner.daysRemaining(deadline:next,now:now,calendar:calendar) == 1)
  #expect(DailyPlanner.daysRemaining(deadline:later,now:now,calendar:calendar) == 3)
  #expect(DailyPlanner.daysRemaining(deadline:now.addingTimeInterval(-86400),now:now,calendar:calendar) == 1)
  #expect(DailyPlanner.daysRemaining(deadline:nil,now:now,calendar:calendar) == 30)
 }
}

struct MultiGoalOverlappingIntegrationTests {
 @Test @MainActor func overlappingGoalsDoNotConsumeSharedMinutesTwice() throws {
  let database=try AppDatabase()
  let materialID=UUID(),ruleID=UUID(),rowID=UUID(),now=Date()
  let material=StudyMaterialRecord(id:materialID,title:"Chemistry",subject:"Химия",topic:"Кислоты",kind:.quiz,source:.created,createdAt:now,updatedAt:now)
  let row=KnowledgeRow(id:rowID,materialID:materialID,position:0,values:["q":"HCl?","a":"Соляная"])
  let rule=QuestionRule(id:ruleID,materialID:materialID,kind:.card,promptFieldKey:"q",answerFieldKey:"a",promptFieldKeys:["q"],answers:[.init(template:"{1}",fieldKeys:["a"],correct:true)],enabled:true)
  let repository=MaterialRepository(database:database)
  try repository.save(material:material,fields:[],rows:[row],rules:[rule])
  let ref=CourseRuleReference(materialID:materialID,ruleID:ruleID)
  let goal1=LearningGoal(id:UUID(),title:"First",questionSets:[ref],masteryTarget:90,deadline:now,state:.active)
  let goal2=LearningGoal(id:UUID(),title:"Second",questionSets:[ref],masteryTarget:90,deadline:now,state:.active)
  let course=StudyCourse(id:UUID(),title:"Chemistry",description:"",subject:"Химия",audience:"ЕГЭ",estimatedMinutes:nil,author:nil,language:"ru",coverSymbol:"book",source:.created,sections:[],goals:[goal1,goal2],createdAt:now,updatedAt:now)
  let profile=StudyProfile(defaultDailyMinutes:20,customDays:[],updatedAt:now)
  let plan=DailyPlanner.make(courses:[course],materials:MaterialStore(repository:repository),learning:LearningStore(questions:[],repository:LearningRepository(database:database)),profile:profile,date:now)
  #expect(plan.goals.count == 1)
  #expect(plan.goals.first?.goalID == goal1.id)
  #expect(plan.goals.first?.minutes == 20)
  #expect(plan.goals.first?.questions.count == 1)
 }
}

@MainActor struct StagedChemistryRouteTests {
    @Test func inorganicThenOrganicThenFullReviewAtSeventyPercent() throws {
        let db = try AppDatabase()
        let repo = MaterialRepository(database: db)
        var sections: [CourseSection] = []
        var refs: [CourseRuleReference] = []
        var knowledgeIDs: [UUID] = []
        for (index, name) in ["Неорганическая", "Органическая"].enumerated() {
            let mid = UUID(), rid = UUID(), rowID = UUID()
            let material = StudyMaterialRecord(id: mid, title: name, subject: "Химия", topic: name,
                kind: .quiz, source: .created, createdAt: .now, updatedAt: .now)
            let row = KnowledgeRow(id: rowID, materialID: mid, position: 0, values: ["q": "Q\(index)", "a": "A"])
            let rule = QuestionRule(id: rid, materialID: mid, kind: .card,
                promptFieldKey: "q", answerFieldKey: "a", promptFieldKeys: ["q"],
                answers: [.init(template: "{1}", fieldKeys: ["a"], correct: true)], enabled: true)
            try repo.save(material: material, fields: [], rows: [row], rules: [rule])
            let ref = CourseRuleReference(materialID: mid, ruleID: rid)
            refs.append(ref)
            let topic = CourseTopic(id: UUID(), title: name, questionSets: [ref])
            sections.append(CourseSection(id: UUID(), title: name, description: "", estimatedMinutes: nil, topics: [topic]))
            let fetched = try repo.content(id: mid)
            let content = try #require(fetched)
            let question = try #require(StudyQuestionBuilder.questions(for: ref, content: content).first)
            knowledgeIDs.append(question.knowledgeID)
        }
        let goal = LearningGoal(id: UUID(), title: "Химия", questionSets: refs, masteryTarget: 90, deadline: nil, state: .active)
        var course = StudyCourse(id: UUID(), title: "Химия", description: "", subject: "Химия", audience: "ЕГЭ",
            estimatedMinutes: nil, author: nil, language: "ru", coverSymbol: "book", source: .created,
            sections: sections, goals: [goal], createdAt: .now, updatedAt: .now)
        course.stagedLearning = StagedLearningRoute(sectionIDs: sections.map(\.id), threshold: 70)
        let store = MaterialStore(repository: repo)
        #expect(DailyPlanner.stagedReferences(course: course, goal: goal, materials: store, states: [:]) == [refs[0]])
        let known = LearningState(intervalDays: 10, streak: 5, nextDueAt: .now)
        #expect(DailyPlanner.stagedReferences(course: course, goal: goal, materials: store,
            states: [knowledgeIDs[0]: known]) == [refs[1]])
        #expect(DailyPlanner.stagedReferences(course: course, goal: goal, materials: store,
            states: [knowledgeIDs[0]: known, knowledgeIDs[1]: known]) == refs)
        let encoded = try JSONEncoder().encode(course)
        #expect(try JSONDecoder().decode(StudyCourse.self, from: encoded).stagedLearning == course.stagedLearning)
        course.stagedLearning = nil
        #expect(DailyPlanner.stagedReferences(course: course, goal: goal, materials: store, states: [:]) == refs)
    }
}

@MainActor struct ChemistryFirstInstallTests {
    @Test func twoStudentChemistryProgressSurvivesOfflineRestartAndRepeatedProvisioning() throws {
        let source = try ChemistryPilotProvisioner.bundledSource()
        let fm = FileManager.default
        let support = fm.temporaryDirectory.appendingPathComponent("botai-chemistry-two-students-" + UUID().uuidString)
        defer { try? fm.removeItem(at: support) }
        let identities: [LocalAccountStorage.Identity] = [.authenticated(UUID()), .authenticated(UUID())]
        var firstQuestion: UUID?
        let attempts = [UUID(), UUID()]
        for (index, identity) in identities.enumerated() {
            let folder = LocalAccountStorage.directory(for: identity, support: support)
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
            let path = folder.appendingPathComponent("learning.sqlite").path
            let db = try AppDatabase(path: path)
            try ChemistryPilotProvisioner.installIfNeeded(database: db, source: source)
            let course = try #require(CourseRepository(database: db).courses().first)
            let ref = try #require(course.goals.first?.questionSets.first)
            let loadedContent = try MaterialRepository(database: db).content(id: ref.materialID)
            let content = try #require(loadedContent)
            let realChemistryQuestion = try #require(StudyQuestionBuilder.questions(for: ref, content: content).first)
            if let firstQuestion { #expect(realChemistryQuestion.id == firstQuestion) }
            firstQuestion = realChemistryQuestion.id
            let learning = LearningRepository(database: db)
            let state = LearningState(intervalDays: index + 1, streak: index + 1, nextDueAt: .now)
            try learning.record(Attempt(id: attempts[index], questionID: realChemistryQuestion.id,
                                        occurredAt: .now, rating: .good), state: state)
            #expect(try learning.load().0.map(\.id) == [attempts[index]])
        }
        let questionID = try #require(firstQuestion)
        // Simulate cold relaunch / app update: reopen each account's own on-disk DB,
        // re-run the normal first-install hook, and verify it cannot reset progress.
        for (index, identity) in identities.enumerated().reversed() {
            let path = LocalAccountStorage.directory(for: identity, support: support)
                .appendingPathComponent("learning.sqlite").path
            let db = try AppDatabase(path: path)
            try ChemistryPilotProvisioner.installIfNeeded(database: db, source: source)
            let learning = LearningRepository(database: db)
            let persisted = try learning.load()
            #expect(persisted.0.count == 1)
            #expect(persisted.0.first?.id == attempts[index])
            #expect(persisted.0.first?.questionID == questionID)
            #expect(persisted.1[questionID]?.streak == index + 1)
            #expect(try CourseRepository(database: db).courses().count == 1)
            #expect(try MaterialRepository(database: db).materials().count == 102)
        }
        #expect(LocalAccountStorage.directoryName(for: identities[0]) != LocalAccountStorage.directoryName(for: identities[1]))
    }

    @Test func bundledChemistryInstallsOnceAndPreservesExistingCourseAndMaterial() throws {
        let source = try ChemistryPilotProvisioner.bundledSource()
        #expect(source.questions.count == 323)
        let db = try AppDatabase()
        try ChemistryPilotProvisioner.installIfNeeded(database: db, source: source)
        let repo = CourseRepository(database: db)
        let installed = try repo.courses()
        let course = try #require(installed.first(where: { $0.id == ChemistryPilotProvisioner.courseID }))
        #expect(course.sections.count == 5)
        #expect(course.topicCount == 25)
        #expect(course.stagedLearning?.threshold == 70)
        #expect(course.stagedLearning?.sectionIDs.count == 2)
        let profileRepo = StudyProfileRepository(database: db)
        #expect(try profileRepo.load().defaultDailyMinutes == 25)
        #expect(try profileRepo.load().minutes(for: 1) == 0)
        let materials = MaterialRepository(database: db)
        #expect(try materials.materials().count == 102)
        let refs = course.goals.flatMap(\.questionSets)
        let questions = try refs.flatMap { ref -> [StudyQuestion] in
            let loaded = try materials.content(id: ref.materialID)
            let content = try #require(loaded)
            return StudyQuestionBuilder.questions(for: ref, content: content)
        }
        #expect(questions.count == 323)
        #expect(Set(questions.map(\.knowledgeID)).count == 323)
        let allChoiceRefs = course.sections.flatMap(\.topics).flatMap(\.questionSets).filter { !refs.contains($0) }
        let choices = try allChoiceRefs.flatMap { ref -> [StudyQuestion] in
            let loaded = try materials.content(id: ref.materialID)
            let content = try #require(loaded)
            return StudyQuestionBuilder.questions(for: ref, content: content)
        }
        #expect(choices.count == 323)
        #expect(choices.allSatisfy { $0.choices.count == 4 && $0.correctChoiceIndexes.count == 1 })
        var edited = course
        edited.description = "Learner progress must survive updates"
        try repo.save(edited)
        try profileRepo.save(StudyProfile(defaultDailyMinutes: 15, customDays: [], updatedAt: .now))
        try ChemistryPilotProvisioner.installIfNeeded(database: db, source: source)
        #expect(try profileRepo.load().defaultDailyMinutes == 15)
        #expect(try repo.courses().count == 1)
        #expect(try repo.courses().first?.description == "Learner progress must survive updates")
        #expect(try materials.materials().count == 102)
        let independent = try AppDatabase()
        #expect(try CourseRepository(database: independent).courses().isEmpty)
        try ChemistryPilotProvisioner.installIfNeeded(database: independent, source: source)
        #expect(try CourseRepository(database: independent).courses().count == 1)
    }
}
