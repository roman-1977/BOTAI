import SwiftUI

struct PersonalQuizView: View {
    let quiz: MyQuiz
    @State private var detail: PersonalQuizDetail?
    @State private var error: String?
    @State private var learningStore: LearningStore?
    @State private var editing = false
    private let service = PersonalQuizService()
    var body: some View {
        Group { if let detail { List { Section { Button("Начать опрос") { learningStore = LearningStore(questions: detail.draft.cards.map { StudyQuestion(id:UUID(),prompt:$0.0,answer:$0.1,kind:.reveal,choices:[],correctChoiceIndexes:[]) }) }.buttonStyle(.borderedProminent); Button("Редактировать") { editing=true } }
Section("Вопросы: \(detail.draft.cards.count)") { ForEach(Array(detail.draft.cards.prefix(50).enumerated()),id:\.offset) { _,c in VStack(alignment:.leading){Text(c.0).font(.headline);Text(c.1).foregroundStyle(.secondary)} } } }
} else if let error { ContentUnavailableView("Не удалось открыть",systemImage:"exclamationmark.triangle",description:Text(error)) } else { ProgressView() } }
        .navigationTitle(quiz.title).task { await load() }
        .sheet(item:$learningStore) { store in LearnSessionView().environment(store) }
        .sheet(isPresented:$editing,onDismiss:{Task{await load()}}) { EditPersonalQuizView(quizID:quiz.id, initial:detail!) }
    }
    private func load() async { do { detail=try await service.load(quiz.id); error=nil } catch { self.error=error.localizedDescription } }
}
extension LearningStore: Identifiable { nonisolated var id:ObjectIdentifier { ObjectIdentifier(self) } }
