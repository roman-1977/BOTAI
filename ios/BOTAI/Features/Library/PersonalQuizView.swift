import SwiftUI

struct PersonalQuizView: View {
    let quiz: MyQuiz
    @Environment(LearningStore.self) private var learning
    @State private var detail: PersonalQuizDetail?
    @State private var error: String?
    @State private var showingLearn=false
    @State private var editing=false
    @State private var choosingGoal=false
    private let service=PersonalQuizService()
    private var questions:[StudyQuestion] { detail.map { QuizQuestionFactory.questions(quizID: quiz.id, cards:$0.draft.cards) } ?? [] }
    private var history:[Attempt] { learning.attempts(for:Set(questions.map(\.id))) }
    var body: some View {
        Group { if let detail { List {
            Section { Button("Начать опрос") { learning.use(questions:questions); showingLearn=true }.buttonStyle(.borderedProminent); Button("Редактировать") { editing=true }; Button("Добавить к цели") { choosingGoal=true } }
            Section("Прогресс") { LabeledContent("Вопросов",value:"\(questions.count)"); LabeledContent("Ответов за всё время",value:"\(history.count)"); LabeledContent("Сегодня",value:"\(history.filter{Calendar.current.isDateInToday($0.occurredAt)}.count)"); LabeledContent("Изучено",value:"\(questions.filter{learning.states[$0.id] != nil}.count) из \(questions.count)") }
            if !history.isEmpty { Section("Последние ответы") { ForEach(history.sorted{$0.occurredAt > $1.occurredAt}.prefix(20)) { a in HStack { Text(a.rating.title); Spacer(); Text(a.occurredAt,style:.relative).foregroundStyle(.secondary) } } } }
            Section("Вопросы") { ForEach(Array(detail.draft.cards.prefix(50).enumerated()),id:\.offset) { _,c in VStack(alignment:.leading){Text(c.0).font(.headline);Text(c.1).foregroundStyle(.secondary)} } }
        } } else if let error { ContentUnavailableView("Не удалось открыть",systemImage:"exclamationmark.triangle",description:Text(error)) } else { ProgressView() } }
        .navigationTitle(quiz.title).task { await load() }
        .sheet(isPresented:$showingLearn) { LearnSessionView().environment(learning) }
        .sheet(isPresented:$choosingGoal) { GoalPickerForQuiz(quizID:quiz.id) }
        .sheet(isPresented:$editing,onDismiss:{Task{await load()}}) { if let detail { EditPersonalQuizView(quizID:quiz.id, initial:detail) } }
    }
    private func load() async { do { detail=try await service.load(quiz.id); error=nil } catch { self.error=error.localizedDescription } }
}
