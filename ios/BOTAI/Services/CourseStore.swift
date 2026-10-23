import Foundation
import Observation

@MainActor @Observable final class CourseStore {
  private(set) var courses: [StudyCourse] = []
  private let repository: CourseRepository?
  private(set) var lastPersistenceError: String?
  init(repository: CourseRepository? = nil) {
    self.repository = repository
    refresh()
  }
  func refresh() {
    guard let repository else { return }
    do {
      courses = try repository.courses()
      lastPersistenceError = nil
    } catch { lastPersistenceError = error.localizedDescription }
  }
  func create(
    title: String, description: String, subject: String, audience: String, minutes: Int?,
    language: String
  ) -> StudyCourse {
    let now = Date()
    let x = StudyCourse(
      id: UUID(), title: title, description: description, subject: subject, audience: audience,
      estimatedMinutes: minutes, author: "Вы", language: language,
      coverSymbol: "graduationcap.fill", source: .created, sections: [], goals: [], createdAt: now,
      updatedAt: now)
    persist { try repository?.save(x) }
    if lastPersistenceError == nil { refresh() }
    return x
  }
  func save(_ course: StudyCourse) {
    do { try saveOrThrow(course) }
    catch { lastPersistenceError = error.localizedDescription }
  }
  func saveOrThrow(_ course: StudyCourse) throws {
    guard let repository else {
      let error = CocoaError(.fileNoSuchFile)
      lastPersistenceError = error.localizedDescription
      throw error
    }
    var updated = course
    updated.updatedAt = Date()
    do {
      try repository.save(updated)
      // The write has committed. A subsequent refresh error must not be
      // reported as a failed write or trigger deletion of its material.
      lastPersistenceError = nil
      refresh()
    } catch {
      lastPersistenceError = error.localizedDescription
      throw error
    }
  }
  func delete(_ id: UUID) {
    persist { try repository?.delete(id) }
    if lastPersistenceError == nil { refresh() }
  }
  private func persist(_ operation: () throws -> Void) {
    do {
      guard repository != nil else { throw CocoaError(.fileNoSuchFile) }
      try operation()
      lastPersistenceError = nil
    } catch { lastPersistenceError = error.localizedDescription }
  }
  @discardableResult
  func removeReferences(to materialID: UUID) -> Bool {
    guard repository != nil else {
      lastPersistenceError = CocoaError(.fileNoSuchFile).localizedDescription
      return false
    }
    var firstError: String?
    for var course in courses {
      var changed = false
      for si in course.sections.indices {
        for ti in course.sections[si].topics.indices {
          let before = course.sections[si].topics[ti].questionSets.count
          course.sections[si].topics[ti].questionSets.removeAll { $0.materialID == materialID }
          changed = changed || before != course.sections[si].topics[ti].questionSets.count
        }
      }
      for gi in course.goals.indices {
        let before = course.goals[gi].questionSets.count
        course.goals[gi].questionSets.removeAll { $0.materialID == materialID }
        changed = changed || before != course.goals[gi].questionSets.count
      }
      if changed {
        save(course)
        if firstError == nil { firstError = lastPersistenceError }
      }
    }
    refresh()
    if let firstError {
      lastPersistenceError = firstError
      return false
    }
    return lastPersistenceError == nil
  }
}
