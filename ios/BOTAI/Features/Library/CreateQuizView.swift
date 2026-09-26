import SwiftUI

struct CreateQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var prompt = ""
    @State private var answer = ""
    @State private var cards: [(String,String)] = []
    @State private var saving = false
    @State private var error: String?
    var body: some View {
        NavigationStack { Form {
            Section("Опросник") { TextField("Название", text: $title); TextField("Описание", text: $description, axis: .vertical) }
            Section("Новая карточка") { TextField("Вопрос", text: $prompt, axis: .vertical); TextField("Ответ", text: $answer, axis: .vertical); Button("Добавить карточку") { cards.append((prompt,answer)); prompt=""; answer="" }.disabled(prompt.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || answer.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) }
            Section("Карточки: \(cards.count)") { ForEach(Array(cards.enumerated()), id: \.offset) { _, card in VStack(alignment:.leading) { Text(card.0).font(.headline); Text(card.1).foregroundStyle(.secondary) } } }
            if let error { Section { Text(error).foregroundStyle(.red) } }
        }.navigationTitle("Новый опросник").toolbar { ToolbarItem(placement:.cancellationAction){Button("Отмена"){dismiss()}}; ToolbarItem(placement:.confirmationAction){Button(saving ? "Сохраняем…" : "Сохранить"){ save() }.disabled(saving || title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || cards.isEmpty)} } }
    }
    private func save() { saving=true; Task { do { try await QuizAuthoringService().createQuiz(title:title, description:description.isEmpty ? nil:description, cards:cards); dismiss() } catch { self.error=error.localizedDescription; saving=false } } }
}
