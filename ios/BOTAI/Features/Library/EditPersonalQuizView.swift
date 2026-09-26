import SwiftUI
struct EditPersonalQuizView: View {
    let quizID: UUID; @State var title:String; @State var description:String; @State var draft:StudySetDraft
    @Environment(\.dismiss) private var dismiss; @State private var saving=false; @State private var error:String?
    private let service=PersonalQuizService()
    init(quizID:UUID,initial:PersonalQuizDetail){self.quizID=quizID;_title=State(initialValue:initial.title);_description=State(initialValue:initial.description ?? "");_draft=State(initialValue:initial.draft)}
    var body:some View { NavigationStack { Form { TextField("Название",text:$title); TextField("Описание",text:$description,axis:.vertical); Section("Пары: \(draft.cards.count)"){ForEach(Array(draft.cards.enumerated()),id:\.offset){_,c in VStack(alignment:.leading){Text(c.0);Text(c.1).foregroundStyle(.secondary)}}}; if let error{Text(error).foregroundStyle(.red)} } .navigationTitle("Редактирование").toolbar { ToolbarItem(placement:.cancellationAction){Button("Отмена"){dismiss()}}; ToolbarItem(placement:.confirmationAction){Button(saving ? "Сохраняем…":"Сохранить"){Task{await save()}}.disabled(saving || title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)} } } }
    private func save() async { saving=true; defer{saving=false}; do{try await service.update(quizID,title:title,description:description,draft:draft);dismiss()}catch{self.error=error.localizedDescription} }
}
