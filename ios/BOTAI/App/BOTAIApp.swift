import SwiftUI

@main
struct BOTAIApp: App {
    @State private var learningStore: LearningStore
    @State private var authStore = AuthStore()
    @State private var materialStore: MaterialStore

    init() {
        var materialRepository: MaterialRepository?
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
            return LearningRepository(database: database)
        }()
        _learningStore = State(initialValue: LearningStore(repository: repository))
        _materialStore = State(initialValue: MaterialStore(repository: materialRepository))
    }

    var body: some Scene { WindowGroup { RootTabView().environment(learningStore).environment(authStore).environment(materialStore).task { await authStore.bootstrap() } } }
}
