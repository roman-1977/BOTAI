import Foundation
import Testing
@testable import BOTAI

struct CoursePersistenceTests {
 @Test func courseSectionsAndGoalsSurviveRepositoryRoundTrip() throws {
  let db = try AppDatabase()
  let repository = CourseRepository(database: db)
  let now = Date()
  let reference = CourseRuleReference(materialID: UUID(), ruleID: UUID())
  let topic = CourseTopic(id: UUID(), title: "Тригонометрия", questionSets: [reference])
  let section = CourseSection(id: UUID(), title: "Алгебра", description: "Повторение", estimatedMinutes: 45, topics: [topic])
  let goal = LearningGoal(id: UUID(), title: "Выучить формулы", questionSets: [reference], masteryTarget: 85, deadline: now.addingTimeInterval(86400), state: .active)
  let course = StudyCourse(id: UUID(), title: "Математика ЕГЭ", description: "Подготовка", subject: "Математика", audience: "11 класс", estimatedMinutes: 120, author: "Автор", language: "Русский", coverSymbol: "graduationcap.fill", source: .created, sections: [section], goals: [goal], createdAt: now, updatedAt: now)
  try repository.save(course)
  let loaded = try #require(repository.courses().first(where: { $0.id == course.id }))
  #expect(loaded.title == course.title)
  #expect(loaded.sections == course.sections)
  #expect(loaded.goals.count == 1)
  #expect(loaded.goals[0].id == goal.id)
  #expect(loaded.goals[0].questionSets == [reference])
  #expect(loaded.goals[0].masteryTarget == 85)
  #expect(loaded.goals[0].state == .active)
  #expect(loaded.goals[0].deadline != nil)
  #expect(loaded.topicCount == 1)
  #expect(loaded.questionSetCount == 1)
  var changed = loaded
  changed.goals[0].state = .completed
  try repository.save(changed)
  #expect(try repository.courses().first(where: { $0.id == course.id })?.goals.first?.state == .completed)
 }

 @Test @MainActor func removingMaterialReferencesPreservesOtherCourseContent() throws {
  let db = try AppDatabase()
  let repository = CourseRepository(database: db)
  let removed = CourseRuleReference(materialID: UUID(), ruleID: UUID())
  let retained = CourseRuleReference(materialID: UUID(), ruleID: UUID())
  let topic = CourseTopic(id: UUID(), title: "Тема", questionSets: [removed, retained])
  let section = CourseSection(id: UUID(), title: "Раздел", description: "", estimatedMinutes: nil, topics: [topic])
  let goal = LearningGoal(id: UUID(), title: "Цель", questionSets: [removed, retained], masteryTarget: 90, deadline: nil, state: .active)
  let now = Date()
  let course = StudyCourse(id: UUID(), title: "Курс", description: "", subject: "", audience: "", estimatedMinutes: nil, author: nil, language: "Русский", coverSymbol: "book", source: .created, sections: [section], goals: [goal], createdAt: now, updatedAt: now)
  try repository.save(course)
  let store = CourseStore(repository: repository)
  #expect(store.removeReferences(to: removed.materialID))
  #expect(store.lastPersistenceError == nil)
  let loaded = try #require(repository.courses().first(where: { $0.id == course.id }))
  #expect(loaded.sections[0].topics[0].questionSets == [retained])
  #expect(loaded.goals[0].questionSets == [retained])
  #expect(loaded.goals[0].state == .active)
  #expect(store.removeReferences(to: removed.materialID))
  let repeated = try #require(repository.courses().first(where: { $0.id == course.id }))
  #expect(repeated.sections[0].topics[0].questionSets == [retained])
  #expect(repeated.goals[0].questionSets == [retained])
 }

 @Test @MainActor func referenceCleanupWithoutDatabaseReportsFailure() {
  let store = CourseStore()
  #expect(!store.removeReferences(to: UUID()))
  #expect(store.lastPersistenceError != nil)
 }

 @Test func legacyCourseWithoutGoalsDecodesToEmptyGoals() throws {
  let now = Date()
  let course = StudyCourse(id: UUID(), title: "Старый курс", description: "", subject: "", audience: "", estimatedMinutes: nil, author: nil, language: "Русский", coverSymbol: "book", source: .created, sections: [], goals: [], createdAt: now, updatedAt: now)
  let encoder = JSONEncoder()
  let data = try encoder.encode(course)
  var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
  object.removeValue(forKey: "goals")
  let legacyData = try JSONSerialization.data(withJSONObject: object)
  let decoded = try JSONDecoder().decode(StudyCourse.self, from: legacyData)
  #expect(decoded.id == course.id)
  #expect(decoded.goals.isEmpty)
 }
}

struct StoreFailureTests {
    @Test @MainActor func courseCreationWithoutDatabaseReportsFailure() {
        let store = CourseStore()
        _ = store.create(title: "Не сохранён", description: "", subject: "", audience: "", minutes: nil, language: "Русский")
        #expect(store.courses.isEmpty)
        #expect(store.lastPersistenceError != nil)
    }

    @Test @MainActor func scheduleWithoutDatabaseDoesNotPretendToSave() {
        let store = StudyProfileStore()
        let original = store.profile
        #expect(!store.save(defaultMinutes: 90, customDays: []))
        #expect(store.profile == original)
        #expect(store.lastPersistenceError != nil)
    }
}
