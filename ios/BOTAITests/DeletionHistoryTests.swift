import Foundation
import Testing
@testable import BOTAI

struct DeletionHistoryTests {
 @Test func deletingMaterialDoesNotDeleteLearningHistory() throws {
  let db=try AppDatabase();let learning=LearningRepository(database:db);let materials=MaterialRepository(database:db)
  let mid=UUID(),qid=UUID(),now=Date()
  let m=StudyMaterialRecord(id:mid,title:"Исторический материал",subject:nil,topic:nil,kind:.reference,source:.created,createdAt:now,updatedAt:now)
  let fields=[MaterialField(id:UUID(),materialID:mid,key:"q",title:"Вопрос",position:0)]
  let rows=[KnowledgeRow(id:UUID(),materialID:mid,position:0,values:["q":"A"])]
  let rules=[QuestionRule(id:qid,materialID:mid,kind:.card,promptFieldKey:"q",answerFieldKey:"q",enabled:true)]
  try materials.save(material:m,fields:fields,rows:rows,rules:rules)
  let attempt=Attempt(id:UUID(),questionID:qid,occurredAt:now,rating:.good)
  try learning.record(attempt,state:.init(intervalDays:1,streak:1,nextDueAt:now.addingTimeInterval(86400)))
  let session=StudySession(id:UUID(),startedAt:now,endedAt:now.addingTimeInterval(60),activeSeconds:60,answered:1,correct:1)
  try learning.saveSession(session)
  try materials.delete(id:mid)
  let loaded=try learning.load()
  #expect(loaded.0.map(\.id) == [attempt.id])
  #expect(loaded.1[qid]?.streak == 1)
  #expect(try learning.sessions().map(\.id) == [session.id])
 }

 @Test func repeatedSessionUpdatesAndMaterialDeletionPreserveTotals() throws {
  let db = try AppDatabase()
  let learning = LearningRepository(database: db)
  let materials = MaterialRepository(database: db)
  let mid = UUID(), qid = UUID(), now = Date()
  let material = StudyMaterialRecord(id: mid, title: "Материал", subject: nil, topic: nil, kind: .reference, source: .created, createdAt: now, updatedAt: now)
  try materials.save(material: material, fields: [], rows: [], rules: [])
  let first = StudySession(id: UUID(), startedAt: now, endedAt: now.addingTimeInterval(10), activeSeconds: 10, answered: 1, correct: 0)
  try learning.saveSession(first)
  var updated = first
  updated.endedAt = now.addingTimeInterval(40)
  updated.activeSeconds = 40
  updated.answered = 3
  updated.correct = 2
  try learning.saveSession(updated)
  try learning.saveSession(updated)
  let attempt = Attempt(id: UUID(), questionID: qid, occurredAt: now, rating: .good)
  try learning.record(attempt, state: .init(intervalDays: 1, streak: 1, nextDueAt: now))
  try materials.delete(id: mid)
  let sessions = try LearningRepository(database: db).sessions()
  #expect(sessions.count == 1)
  #expect(sessions.first?.id == updated.id)
  #expect(sessions.first?.answered == 3)
  #expect(sessions.first?.correct == 2)
  #expect(sessions.first?.activeSeconds == 40)
  let loaded = try LearningRepository(database: db).load()
  #expect(loaded.0.map(\.id) == [attempt.id])
  let analytics = LearningAnalytics(sessions: sessions, attempts: loaded.0, states: loaded.1)
  #expect(analytics.totalAnswered == 3)
  #expect(analytics.totalCorrect == 2)
  #expect(analytics.totalSeconds == 40)
 }

 @Test func deletingCourseDoesNotDeleteLearningHistory() throws {
  let db=try AppDatabase();let learning=LearningRepository(database:db);let courses=CourseRepository(database:db)
  let now=Date(),qid=UUID()
  let course=StudyCourse(id:UUID(),title:"Курс",description:"",subject:"",audience:"",estimatedMinutes:nil,author:nil,language:"Русский",coverSymbol:"graduationcap.fill",source:.created,sections:[],goals:[],createdAt:now,updatedAt:now)
  try courses.save(course)
  let attempt=Attempt(id:UUID(),questionID:qid,occurredAt:now,rating:.hard)
  try learning.record(attempt,state:.init(intervalDays:1,streak:1,nextDueAt:now))
  try courses.delete(course.id)
  #expect(try courses.courses().isEmpty)
  #expect(try learning.load().0.count == 1)
 }
}
