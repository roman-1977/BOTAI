import Foundation
import PDFKit
import Testing
@testable import BOTAI

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
