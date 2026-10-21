import SwiftUI
import ZIPFoundation

@main
struct BOTAIApp: App {
    @State private var learningStore: LearningStore
    @State private var authStore = AuthStore()
    @State private var materialStore: MaterialStore
    @State private var courseStore: CourseStore
    @State private var studyProfileStore: StudyProfileStore
    @State private var activeIdentity: LocalAccountStorage.Identity = .guest

    init() {
        var materialRepository: MaterialRepository?
        var courseRepository: CourseRepository?
        var studyProfileRepository: StudyProfileRepository?
        let repository: LearningRepository? = {
            guard let support = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
            let isUITesting = ProcessInfo.processInfo.arguments.contains("-botai-ui-testing")
            let folderName = isUITesting ? "BOTAI-UITests" : "BOTAI"
            let folder = support.appending(path: folderName, directoryHint: .isDirectory)
            if isUITesting && ProcessInfo.processInfo.arguments.contains("-botai-reset-ui-test-data") {
                try? FileManager.default.removeItem(at: folder)
            }
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
        if ProcessInfo.processInfo.arguments.contains("-botai-seed-import-fixture") {
            Self.seedImportFixture()
        }
        _learningStore = State(initialValue: LearningStore(repository: repository))
        let materials = MaterialStore(repository: materialRepository)
        if ProcessInfo.processInfo.arguments.contains("-botai-seed-course-material") {
            let table = ImportedTable(headers: ["Термин", "Значение"], rows: [["Кислота", "Acid"]])
            try? materials.saveCSV(title: "Учебный материал UI", table: table, mappings: [CardMapping(from: 0, to: 1)])
        }
        _materialStore = State(initialValue: materials)
        _courseStore = State(initialValue: CourseStore(repository: courseRepository))
        _studyProfileStore = State(initialValue: StudyProfileStore(repository: studyProfileRepository))
    }

    private static func seedImportFixture() {
        let fm = FileManager.default
        guard let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let root = fm.temporaryDirectory.appendingPathComponent("botai-ui-fixture-\(UUID().uuidString)", isDirectory: true)
        do {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? fm.removeItem(at: root) }
            let manifest = """
            {"formatVersion":1,"title":"BOTAI UI Fixture","kind":"reference","fields":[{"key":"term","title":"Term","position":0,"type":"text"},{"key":"meaning","title":"Meaning","position":1,"type":"text"}],"rows":[{"term":"Apple","meaning":"Fruit"}],"questionSets":[{"kind":"card","promptTemplate":"{1}","promptFieldKeys":["term"],"answers":[{"template":"{1}","fieldKeys":["meaning"],"correct":true}],"showCorrectCount":false,"enabled":true}]}
            """
            try Data(manifest.utf8).write(to: root.appendingPathComponent("manifest.json"))
            let target = documents.appendingPathComponent("BOTAI-UI-Fixture.botai")
            try? fm.removeItem(at: target)
            try fm.zipItem(at: root, to: target, shouldKeepParent: false)
        } catch {
            assertionFailure("Unable to seed BOTAI UI fixture: \(error)")
        }
    }

    @MainActor
    private func switchStorageIfNeeded() {
        let identity = authStore.localIdentity
        guard identity != activeIdentity else { return }
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else { return }
        let uiTesting = ProcessInfo.processInfo.arguments.contains("-botai-ui-testing")
        let folder = LocalAccountStorage.directory(for: identity, support: support, uiTesting: uiTesting)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let database = try AppDatabase(path: folder.appendingPathComponent("learning.sqlite").path)
            // Replace all stores together so no authenticated identity sees another account's data.
            learningStore = LearningStore(repository: LearningRepository(database: database))
            materialStore = MaterialStore(repository: MaterialRepository(database: database))
            courseStore = CourseStore(repository: CourseRepository(database: database))
            studyProfileStore = StudyProfileStore(repository: StudyProfileRepository(database: database))
            activeIdentity = identity
        } catch {
            assertionFailure("Unable to open identity-scoped storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(learningStore)
                .environment(authStore)
                .environment(materialStore)
                .environment(courseStore)
                .environment(studyProfileStore)
                .task {
                    await authStore.bootstrap()
                    switchStorageIfNeeded()
                }
                .onChange(of: authStore.userID) { _, _ in switchStorageIfNeeded() }
        }
    }
}
