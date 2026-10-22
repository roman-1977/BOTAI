import SwiftUI
import ZIPFoundation
import Network

/// Observe connectivity restoration even when the app never leaves the foreground.
/// Reachability is only a retry signal; Supabase must still verify the account.
@MainActor @Observable
final class ConnectivityRetrySignal {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "BOTAI.connectivity-monitor")
    private(set) var restorationCount = 0
    private var wasUnavailable = false
    private var started = false

    static func shouldRetry(previouslyUnavailable: Bool, nowAvailable: Bool) -> Bool {
        previouslyUnavailable && nowAvailable
    }

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if path.status == .satisfied {
                    if Self.shouldRetry(previouslyUnavailable: self.wasUnavailable, nowAvailable: true) {
                        self.restorationCount += 1
                    }
                    self.wasUnavailable = false
                } else {
                    self.wasUnavailable = true
                }
            }
        }
        monitor.start(queue: queue)
    }
}

@main
struct BOTAIApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var learningStore: LearningStore
    @State private var authStore = AuthStore()
    @State private var connectivity = ConnectivityRetrySignal()
    @State private var materialStore: MaterialStore
    @State private var courseStore: CourseStore
    @State private var studyProfileStore: StudyProfileStore
    @State private var activeIdentity: LocalAccountStorage.Identity = .guest
    @State private var didResolveInitialIdentity = false
    @State private var storageFailure: String?
    @State private var syncService: SyncService?

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
        _storageFailure = State(initialValue: repository == nil ? "Не удалось открыть локальную базу данных. Проверьте свободное место и повторите попытку." : nil)
        _learningStore = State(initialValue: LearningStore(repository: repository))
        let materials = MaterialStore(repository: materialRepository)
        if ProcessInfo.processInfo.arguments.contains("-botai-seed-course-material") {
            // Isolated UI fixture: optional second card exercises an interrupted multi-question session.
            let rows = ProcessInfo.processInfo.arguments.contains("-botai-seed-two-course-questions")
                ? [["Кислота", "Acid"], ["Основание", "Base"]] : [["Кислота", "Acid"]]
            let table = ImportedTable(headers: ["Термин", "Значение"], rows: rows)
            if !ProcessInfo.processInfo.arguments.contains("-botai-seed-choice-course-material") || ProcessInfo.processInfo.arguments.contains("-botai-seed-mixed-course-material") {
                try? materials.saveCSV(title: "Учебный материал UI", table: table, mappings: [CardMapping(from: 0, to: 1)])
            }
            if ProcessInfo.processInfo.arguments.contains("-botai-seed-choice-course-material") {
                var rule = DraftQuestionRule()
                rule.fields = [0]
                rule.template = "{1}"
                var correct = DraftAnswer()
                correct.fields = [1]
                correct.template = "{1}"
                correct.correct = true
                var distractor = DraftAnswer()
                distractor.fields = [2]
                distractor.template = "{1}"
                distractor.correct = false
                if ProcessInfo.processInfo.arguments.contains("-botai-seed-multichoice-course-material") {
                    var secondCorrect = DraftAnswer()
                    secondCorrect.fields = [3]
                    secondCorrect.template = "{1}"
                    secondCorrect.correct = true
                    rule.answers = [correct, secondCorrect, distractor]
                } else {
                    rule.answers = [correct, distractor]
                }
                let choiceTable = ImportedTable(headers: ["Вопрос", "Ответ", "Неверный ответ", "Второй ответ"],
                    rows: [["HCl — какая кислота?", "Соляная", "Серная", "Хлороводородная"],
                           ["H2SO4 — какая кислота?", "Серная", "Соляная", "Сульфатная"],
                           ["HNO3 — какая кислота?", "Азотная", "Фосфорная", "Нитратная"],
                           ["H3PO4 — какая кислота?", "Фосфорная", "Азотная", "Ортофосфорная"]])
                try? materials.saveCSV(title: "Тестовый материал UI", table: choiceTable,
                    ruleDrafts: [rule])
            }
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
    @discardableResult
    private func switchStorageIfNeeded() -> Bool {
        let identity = authStore.localIdentity
        guard identity != activeIdentity || storageFailure != nil else {
            if !authStore.isAuthenticated { syncService = nil }
            else if syncService == nil {
                // The same account can return online after an offline-only cold launch.
                // Rebind sync to the already opened account database, never to guest data.
                guard let support = try? FileManager.default.url(
                    for: .applicationSupportDirectory, in: .userDomainMask,
                    appropriateFor: nil, create: true
                ) else { return false }
                let uiTesting = ProcessInfo.processInfo.arguments.contains("-botai-ui-testing")
                let folder = LocalAccountStorage.directory(for: identity, support: support, uiTesting: uiTesting)
                guard let database = try? AppDatabase(path: folder.appendingPathComponent("learning.sqlite").path) else {
                    storageFailure = "Не удалось повторно открыть базу для синхронизации"
                    return false
                }
                let repository = LearningRepository(database: database)
                syncService = authStore.userID.map { SyncService(repository: repository, mappings: RemoteQuestionMappingRepository(database: database), boundAccountID: $0) }
            }
            return true
        }
        // Invalidate the old account's sync service before attempting any database switch.
        syncService = nil
        guard let support = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        ) else {
            storageFailure = "Не удалось открыть каталог данных приложения"
            return false
        }
        let uiTesting = ProcessInfo.processInfo.arguments.contains("-botai-ui-testing")
        let folder = LocalAccountStorage.directory(for: identity, support: support, uiTesting: uiTesting)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let database = try AppDatabase(path: folder.appendingPathComponent("learning.sqlite").path)
            // Replace all stores together so no authenticated identity sees another account's data.
            let learningRepository = LearningRepository(database: database)
            learningStore = LearningStore(repository: learningRepository)
            // Recreate sync with the exact database for the newly authenticated identity.
            // Guest mode never owns an authenticated sync service.
            syncService = authStore.isAuthenticated ? authStore.userID.map { SyncService(repository: learningRepository, mappings: RemoteQuestionMappingRepository(database: database), boundAccountID: $0) } : nil
            materialStore = MaterialStore(repository: MaterialRepository(database: database))
            courseStore = CourseStore(repository: CourseRepository(database: database))
            studyProfileStore = StudyProfileStore(repository: StudyProfileRepository(database: database))
            activeIdentity = identity
            storageFailure = nil
            return true
        } catch {
            storageFailure = error.localizedDescription
            return false
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if didResolveInitialIdentity && !authStore.isBootstrapping && !authStore.didFailBootstrap {
                    RootTabView()
                        .id(LocalAccountStorage.directoryName(for: activeIdentity))
                }
                else if storageFailure != nil {
                    ContentUnavailableView {
                        Label("Хранилище недоступно", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text(storageFailure ?? "Не удалось открыть локальную базу данных")
                    } actions: {
                        Button("Повторить") {
                            didResolveInitialIdentity = switchStorageIfNeeded()
                        }
                    }
                }
                else if authStore.didFailBootstrap {
                    VStack(spacing: 16) {
                        Text("Не удалось проверить учётную запись")
                        Text("Проверьте подключение и повторите попытку.")
                        Button("Повторить") {
                            Task {
                                await authStore.bootstrap()
                                didResolveInitialIdentity = !authStore.didFailBootstrap && switchStorageIfNeeded()
                            }
                        }
                    }
                    .padding()
                } else { ProgressView() }
            }
                .environment(learningStore)
                .environment(authStore)
                .environment(materialStore)
                .environment(courseStore)
                .environment(studyProfileStore)
                .task {
                    connectivity.start()
                    await authStore.bootstrap()
                    didResolveInitialIdentity = !authStore.didFailBootstrap && switchStorageIfNeeded()
                    if didResolveInitialIdentity, let syncService {
                        await syncService.flush(questions: learningStore.questions)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active, didResolveInitialIdentity else { return }
                    Task {
                        if authStore.isOfflineLocalSession {
                            guard await authStore.reconnectOfflineSession() else { return }
                            guard switchStorageIfNeeded() else { return }
                        }
                        guard let syncService else { return }
                        await syncService.flush(questions: learningStore.questions)
                    }
                }
                .onChange(of: connectivity.restorationCount) { _, _ in
                    guard didResolveInitialIdentity else { return }
                    Task {
                        if authStore.isOfflineLocalSession {
                            guard await authStore.reconnectOfflineSession() else { return }
                            guard switchStorageIfNeeded() else { return }
                        }
                        guard let syncService else { return }
                        await syncService.flush(questions: learningStore.questions)
                    }
                }
                .onChange(of: learningStore.completedSessionSignal) { _, _ in
                    guard let syncService else { return }
                    let questions = learningStore.questions
                    Task { await syncService.flush(questions: questions) }
                }
                .onChange(of: authStore.userID) { _, _ in
                    didResolveInitialIdentity = false
                    guard !authStore.isBootstrapping && !authStore.didFailBootstrap else { return }
                    didResolveInitialIdentity = switchStorageIfNeeded()
                    if didResolveInitialIdentity, let syncService {
                        let questions = learningStore.questions
                        Task { await syncService.flush(questions: questions) }
                    }
                }
        }
    }
}
