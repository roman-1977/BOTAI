import SwiftUI
import CryptoKit
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

    // Beta release: never erase learning progress on launch or account switch.
    // Remote learning sync remains suspended until legacy pilot cloud data can
    // be reconciled without rehydrating deleted progress into learner accounts.
    private static let betaLearningSyncEnabled = false

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
            if !isUITesting || ProcessInfo.processInfo.arguments.contains("-botai-seed-chemistry") {
                do { try ChemistryPilotProvisioner.installIfNeeded(database: database) }
                catch { return nil }
            }
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
            else if Self.betaLearningSyncEnabled && syncService == nil {
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
            syncService = Self.betaLearningSyncEnabled && authStore.isAuthenticated ? authStore.userID.map { SyncService(repository: learningRepository, mappings: RemoteQuestionMappingRepository(database: database), boundAccountID: $0) } : nil
            // Seed only the first-time chemistry curriculum. Stable material IDs
            // and the course marker prevent re-import on future launches/updates.
            if !uiTesting || ProcessInfo.processInfo.arguments.contains("-botai-seed-chemistry") {
                try ChemistryPilotProvisioner.installIfNeeded(database: database)
            }
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
                if didResolveInitialIdentity && storageFailure == nil && !authStore.isBootstrapping && !authStore.didFailBootstrap {
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

/// First-install chemistry curriculum. Runs for each account-local database,
/// never resets attempts, learning states, or previously provisioned courses.
@MainActor enum ChemistryPilotProvisioner {
    struct Source: Decodable {
        let questions: [Entry]
    }
    struct Entry: Decodable {
        struct Choice: Decodable { let key: String; let text: String }
        let id: String
        let section: String
        let topic: String
        let knowledge_set: String
        let question: String
        let answer: String
        let choices: [Choice]
        let correct_choice: String
    }

    static func stableUUID(_ key: String) -> UUID {
        let digest = Array(SHA256.hash(data: Data("BOTAI:chemistry:pilot:v1:\(key)".utf8)))
        var b = Array(digest.prefix(16))
        b[6] = (b[6] & 0x0f) | 0x50
        b[8] = (b[8] & 0x3f) | 0x80
        return UUID(uuid: (b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]))
    }

    static let courseID = stableUUID("course")

    static func bundledSource() throws -> Source {
        guard let asset = NSDataAsset(name: "ChemistryPilot") else {
            throw NSError(domain: "BOTAI.Chemistry", code: 1, userInfo: [NSLocalizedDescriptionKey: "Учебный курс химии отсутствует в сборке"])
        }
        return try JSONDecoder().decode(Source.self, from: asset.data)
    }

    static func installIfNeeded(database: AppDatabase, source: Source? = nil) throws {
        let courses = CourseRepository(database: database)
        if try courses.courses().contains(where: { $0.id == courseID }) { return }
        let data = try source ?? bundledSource()
        guard data.questions.count == 323, Set(data.questions.map(\.id)).count == 323 else {
            throw NSError(domain: "BOTAI.Chemistry", code: 2, userInfo: [NSLocalizedDescriptionKey: "Неполный набор химии"])
        }
        let groups = Dictionary(grouping: data.questions) {
            "\($0.section)|\($0.topic)|\($0.knowledge_set)|\($0.correct_choice)"
        }
        let materials = MaterialRepository(database: database)
        let now = Date()
        var topicRefs: [String: [CourseRuleReference]] = [:]
        var goalRefs: [CourseRuleReference] = []
        for key in groups.keys.sorted() {
            guard let entries = groups[key], let first = entries.first else { continue }
            let mid = stableUUID("material:" + key)
            let cardID = stableUUID("card:" + key)
            let choiceID = stableUUID("choice:" + key)
            let fields = ["question", "answer", "A", "B", "C", "D"].enumerated().map {
                MaterialField(id: stableUUID("field:\(key):\($0.element)"), materialID: mid,
                              key: $0.element, title: $0.element, position: $0.offset)
            }
            let rows = entries.sorted { $0.id < $1.id }.enumerated().map { index, entry -> KnowledgeRow in
                var values = ["question": entry.question, "answer": entry.answer]
                for choice in entry.choices { values[choice.key] = choice.text }
                return KnowledgeRow(id: stableUUID("row:" + entry.id), materialID: mid,
                                    position: index, values: values)
            }
            let card = QuestionRule(id: cardID, materialID: mid, kind: .card,
                promptFieldKey: "question", answerFieldKey: "answer", promptFieldKeys: ["question"],
                answers: [QuestionAnswerRule(template: "{1}", fieldKeys: ["answer"], correct: true)], enabled: true)
            let choice = QuestionRule(id: choiceID, materialID: mid, kind: .singleChoice,
                promptFieldKey: "question", answerFieldKey: "answer", promptFieldKeys: ["question"],
                answers: ["A", "B", "C", "D"].map {
                    QuestionAnswerRule(template: "{1}", fieldKeys: [$0], correct: $0 == first.correct_choice)
                }, enabled: true)
            let record = StudyMaterialRecord(id: mid, title: first.knowledge_set,
                subject: "Химия", topic: first.topic, description: first.section,
                author: "BOTAI Pilot", kind: .quiz, source: .created, createdAt: now, updatedAt: now)
            try materials.save(material: record, fields: fields, rows: rows, rules: [card, choice])
            let cardRef = CourseRuleReference(materialID: mid, ruleID: cardID)
            let choiceRef = CourseRuleReference(materialID: mid, ruleID: choiceID)
            topicRefs[first.section + "|" + first.topic, default: []].append(contentsOf: [cardRef, choiceRef])
            goalRefs.append(cardRef)
        }
        let sections = Dictionary(grouping: data.questions, by: \.section).keys.sorted().map { name -> CourseSection in
            let topics = Set(data.questions.filter { $0.section == name }.map(\.topic)).sorted().map { topic in
                CourseTopic(id: stableUUID("topic:\(name):\(topic)"), title: topic,
                            questionSets: topicRefs[name + "|" + topic] ?? [])
            }
            return CourseSection(id: stableUUID("section:" + name), title: name,
                                 description: "", estimatedMinutes: nil, topics: topics)
        }
        let goal = LearningGoal(id: stableUUID("goal"), title: "Освоить химию",
            questionSets: goalRefs, masteryTarget: 90, deadline: nil, state: .active,
            guidance: CourseLearningGuidance(priority: .elevated,
                rationale: "Химия — приоритет подготовки к ЕГЭ", difficulty: 4,
                recommendedDailyMinutes: 25))
        var course = StudyCourse(id: courseID, title: "ЕГЭ — Химия", description: "Учебный курс химии",
            subject: "Химия", audience: "ЕГЭ", estimatedMinutes: nil,
            author: "BOTAI Pilot", language: "ru", coverSymbol: "flask.fill",
            source: .created, sections: sections, goals: [goal], createdAt: now, updatedAt: now)
        let stages = ["Неорганическая химия", "Органическая химия"]
        guard stages.allSatisfy({ name in sections.contains(where: { $0.title == name }) }) else {
            throw NSError(domain: "BOTAI.Chemistry", code: 3, userInfo: [NSLocalizedDescriptionKey: "Разделы курса химии отсутствуют"])
        }
        course.stagedLearning = StagedLearningRoute(sectionIDs: stages.map { stableUUID("section:" + $0) }, threshold: 70)
        // Preserve a learner's chosen schedule. Only a truly new profile gets
        // the chemistry pilot's teacher-suggested 25-minute daily default.
        let profileRepo = StudyProfileRepository(database: database)
        if try profileRepo.history().isEmpty {
            try profileRepo.save(StudyProfile(defaultDailyMinutes: 25,
                customDays: [StudyDayPlan(weekday: 1, minutes: 0)], updatedAt: now))
        }
        // The course is the completion marker, saved only after every material.
        // A failed import can safely resume on next launch using stable IDs.
        try courses.save(course)
    }
}
