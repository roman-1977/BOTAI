import Foundation
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

struct RestDayAndPDFReportTests {
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
