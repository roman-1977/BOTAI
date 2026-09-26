import SwiftUI

@main
struct BOTAIApp: App {
    @State private var learningStore = LearningStore()
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(learningStore)
        }
    }
}
