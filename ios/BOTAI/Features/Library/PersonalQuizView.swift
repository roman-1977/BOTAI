import SwiftUI

struct PersonalQuizView: View {
    let quiz: MyQuiz
    @Environment(LearningStore.self) private var learning
    @State private var detail: PersonalQuizDetail?
    @State private var error: String?
    @State private var showingLearn=false
    @State private var editing=false
    private let service=PersonalQuizService()
    private var questions:[StudyQuestion] { detail.map { QuizQuestionFactory.questions(quizID: quiz.id, cards:$0.draft.cards) } ?? [] }
    private var history:[Attempt] { learning.attempts(for:Set(questions.map(\.id))) }
    var body: some View {
        Group { if let detail { List {
            Section { Button("Начать опрос") { learning.use(questions:questions); showingLearn=true }.buttonStyle(.borderedProminent); NavigationLink("Прогресс") { QuizProgressView(questions:questions) }; NavigationLink("История") { QuizHistoryView(questions:questions) }; Button("Редактировать") { editing=true } }
            Section("Сейчас") { let s=learning.stats(for:questions); LabeledContent("Изучено",value:"\(s.learned) из \(s.total)"); LabeledContent("Ответов сегодня",value:"\(s.today)"); ProgressView(value:s.coverage) }
            Section("Вопросы") { ForEach(Array(detail.draft.cards.prefix(50).enumerated()),id:\.offset) { _,c in VStack(alignment:.leading){Text(c.0).font(.headline);Text(c.1).foregroundStyle(.secondary)} } }
        } } else if let error { ContentUnavailableView("Не удалось открыть",systemImage:"exclamationmark.triangle",description:Text(error)) } else { ProgressView() } }
        .navigationTitle(quiz.title).task { await load() }
        .sheet(isPresented:$showingLearn) { LearnSessionView().environment(learning) }
        .sheet(isPresented:$editing,onDismiss:{Task{await load()}}) { if let detail { EditPersonalQuizView(quizID:quiz.id, initial:detail) } }
    }
    private func load() async { do { detail=try await service.load(quiz.id); error=nil } catch { self.error=error.localizedDescription } }
}
