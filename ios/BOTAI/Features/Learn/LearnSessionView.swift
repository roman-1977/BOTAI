import SwiftUI

struct LearnSessionView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var revealed = false
    @State private var selection: Set<Int> = []
    @State private var finished = false

    var body: some View { NavigationStack { finished ? AnyView(resultView) : AnyView(questionView) } }
    private var question: StudyQuestion { store.questions[index] }
    private var questionView: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(index), total: Double(store.questions.count))
            Text("\(index + 1) из \(store.questions.count)").font(.caption).foregroundStyle(.secondary)
            Spacer(); Text(question.prompt).font(.title2.bold()).multilineTextAlignment(.center); answerArea; Spacer()
        }.padding().navigationTitle("БОТАТЬ").navigationBarTitleDisplayMode(.inline)
    }
    @ViewBuilder private var answerArea: some View {
        if question.kind == .reveal {
            if revealed { Text(question.answer).font(.title3); ratingButtons }
            else { Button("Показать ответ") { revealed = true }.buttonStyle(.borderedProminent).controlSize(.large) }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { i, choice in
                    Button { toggle(i) } label: { HStack { Text(choice); Spacer(); if selection.contains(i) { Image(systemName: "checkmark.circle.fill") } }.padding().frame(maxWidth: .infinity) }.buttonStyle(.bordered)
                }
                if revealed { Text(selection == question.correctChoiceIndexes ? "Верно" : "Правильный ответ: \(question.answer)").font(.headline); ratingButtons }
                else { Button("Ответить") { revealed = true }.buttonStyle(.borderedProminent).disabled(selection.isEmpty) }
            }
        }
    }
    private var ratingButtons: some View { HStack { ForEach(RecallRating.allCases, id: \.self) { r in Button(r.title) { submit(r) }.buttonStyle(.bordered) } } }
    private var resultView: some View { VStack(spacing: 20) { Spacer(); Image(systemName: "checkmark.circle.fill").font(.system(size: 60)); Text("Занятие завершено").font(.title.bold()); Text("\(store.questions.count) вопросов"); Button("Готово") { dismiss() }.buttonStyle(.borderedProminent).controlSize(.large); Spacer() }.padding() }
    private func toggle(_ i: Int) { if question.kind == .singleChoice { selection = [i] } else if selection.contains(i) { selection.remove(i) } else { selection.insert(i) } }
    private func submit(_ r: RecallRating) { store.record(question: question, rating: r); if index + 1 < store.questions.count { index += 1; revealed = false; selection = [] } else { finished = true } }
}
