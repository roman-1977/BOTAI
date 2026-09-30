import SwiftUI

@main
struct BOTAIApp: App {
    @State private var learningStore: LearningStore
    @State private var authStore = AuthStore()
    @State private var materialStore: MaterialStore
    @State private var courseStore: CourseStore
    @State private var studyProfileStore: StudyProfileStore

    init() {
        var materialRepository: MaterialRepository?
        var courseRepository: CourseRepository?
        var studyProfileRepository: StudyProfileRepository?
        let repository: LearningRepository? = {
            guard let support = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
            let folder = support.appending(path: "BOTAI", directoryHint: .isDirectory)
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                assertionFailure("Unable to create BOTAI application support directory: \(error)")
                return nil
            }
            guard FileManager.default.fileExists(atPath: folder.path) else { return nil }
            guard let database = try? AppDatabase(path: folder.appending(path: "learning.sqlite").path) else { return nil }
            materialRepository = MaterialRepository(database: database)
            courseRepository = CourseRepository(database: database)
            studyProfileRepository = StudyProfileRepository(database: database)
            return LearningRepository(database: database)
        }()
        _learningStore = State(initialValue: LearningStore(repository: repository))
        _materialStore = State(initialValue: MaterialStore(repository: materialRepository))
        _courseStore = State(initialValue: CourseStore(repository: courseRepository))
        _studyProfileStore = State(initialValue: StudyProfileStore(repository: studyProfileRepository))
    }

    var body: some Scene { WindowGroup { RootTabView().environment(learningStore).environment(authStore).environment(materialStore).environment(courseStore).environment(studyProfileStore).task { await authStore.bootstrap() } } }
}
