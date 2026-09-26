import SwiftUI

@main
struct BOTAIApp: App {
    @State private var learningStore: LearningStore

    init() {
        let repository: LearningRepository? = {
            guard let support = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { return nil }
            let folder = support.appending(path: "BOTAI", directoryHint: .isDirectory)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            guard let database = try? AppDatabase(path: folder.appending(path: "learning.sqlite").path()) else { return nil }
            return LearningRepository(database: database)
        }()
        _learningStore = State(initialValue: LearningStore(repository: repository))
    }

    var body: some Scene { WindowGroup { RootTabView().environment(learningStore) } }
}
