import Foundation
import Testing
@testable import BOTAI

struct StudyProfileTests {
 @Test func weekdayOverridesAndWeeklyBudget() {
  let p=StudyProfile(defaultDailyMinutes:30,customDays:[.init(weekday:2,minutes:45),.init(weekday:1,minutes:0)],updatedAt:.now)
  #expect(p.minutes(for:2) == 45);#expect(p.minutes(for:3) == 30);#expect(p.minutes(for:1) == 0);#expect(p.weeklyMinutes == 195)
 }
 @Test func profilePersists() throws {
  let db=try AppDatabase();let repo=StudyProfileRepository(database:db);let p=StudyProfile(defaultDailyMinutes:40,customDays:[.init(weekday:7,minutes:10)],updatedAt:Date(timeIntervalSince1970:123))
  try repo.save(p);#expect(try repo.load() == p)
 }
}

struct ReportingSnapshotPersistenceTests {
  @Test func planHistoryPersistsEveryScheduleRevision() throws {
    let db = try AppDatabase()
    let repo = StudyProfileRepository(database: db)
    let first = StudyProfile(defaultDailyMinutes:25, customDays:[.init(weekday:1,minutes:0)], updatedAt:Date(timeIntervalSince1970:1000))
    let second = StudyProfile(defaultDailyMinutes:40, customDays:[.init(weekday:1,minutes:15)], updatedAt:Date(timeIntervalSince1970:2000))
    try repo.save(first)
    try repo.save(second)
    #expect(try repo.load() == second)
    #expect(try repo.history() == [first,second])
  }

  @Test func forecastUpsertKeepsOneSnapshotPerGoalPerDay() throws {
    let db = try AppDatabase()
    let repo = LearningRepository(database: db)
    let goalID = UUID(), day = "2026-10-22"
    let first = LearningRepository.ForecastSnapshot(goalID:goalID,day:day,calculatedAt:Date(timeIntervalSince1970:1000),forecastAt:nil,known:2,target:10,rate:nil,algorithmVersion:2)
    let updated = LearningRepository.ForecastSnapshot(goalID:goalID,day:day,calculatedAt:Date(timeIntervalSince1970:2000),forecastAt:Date(timeIntervalSince1970:5000),known:4,target:10,rate:0.3,algorithmVersion:2)
    try repo.saveForecast(first)
    try repo.saveForecast(updated)
    #expect(try repo.forecastSnapshots() == [updated])
    let reopened = LearningRepository(database:db)
    #expect(try reopened.forecastSnapshots().count == 1)
  }
}
