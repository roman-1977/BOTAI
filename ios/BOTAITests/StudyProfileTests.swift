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
