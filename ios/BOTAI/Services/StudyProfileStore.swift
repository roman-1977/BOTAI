import Foundation
import Observation

@MainActor @Observable final class StudyProfileStore {
    private let repository: StudyProfileRepository?
    private(set) var profile: StudyProfile
    init(repository: StudyProfileRepository? = nil) { self.repository = repository; profile = (try? repository?.load()) ?? .standard }
    func save(defaultMinutes: Int, customDays: [StudyDayPlan]) {
        profile = StudyProfile(defaultDailyMinutes: defaultMinutes, customDays: customDays, updatedAt: .now)
        try? repository?.save(profile)
    }
}
