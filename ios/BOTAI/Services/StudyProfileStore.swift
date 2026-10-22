import Foundation
import Observation

@MainActor @Observable final class StudyProfileStore {
  private let repository: StudyProfileRepository?
  private(set) var history: [StudyProfile] = []
  private(set) var profile: StudyProfile
  private(set) var lastPersistenceError: String?
  init(repository: StudyProfileRepository? = nil) {
    self.repository = repository
    profile = (try? repository?.load()) ?? .standard
    history = (try? repository?.history()) ?? []
  }
  @discardableResult
  func save(defaultMinutes: Int, customDays: [StudyDayPlan]) -> Bool {
    let updated = StudyProfile(
      defaultDailyMinutes: defaultMinutes, customDays: customDays, updatedAt: .now)
    do {
      guard let repository else { throw CocoaError(.fileNoSuchFile) }
      try repository.save(updated)
      profile = updated
      history.append(updated)
      lastPersistenceError = nil
      return true
    } catch {
      lastPersistenceError = error.localizedDescription
      return false
    }
  }
}
