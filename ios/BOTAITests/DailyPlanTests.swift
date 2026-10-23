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
