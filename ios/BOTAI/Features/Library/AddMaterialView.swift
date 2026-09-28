import SwiftUI
import UniformTypeIdentifiers

struct DraftAnswer: Identifiable, Hashable {
    let id = UUID(); var fields: [Int] = []; var template = "{1}"; var correct = true
}
struct DraftQuestionRule: Identifiable, Hashable {
    let id = UUID(); var fields: [Int] = []; var template = "{1}"; var showCorrectCount = false
    var answers: [DraftAnswer] = [DraftAnswer()]
    var valid: Bool { !fields.isEmpty && !template.isEmpty && (1...6).contains(answers.count) && answers.contains(where: { $0.correct }) && answers.allSatisfy { !$0.fields.isEmpty && !$0.template.isEmpty } }
}

struct AddMaterialView: View {
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var importer=false; @State private var table:ImportedTable?; @State private var title=""; @State private var description=""; @State private var tags=""
    @State private var rules:[DraftQuestionRule]=[]; @State private var error:String?
    private var canSave:Bool { table != nil && !title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty && rules.contains(where:{$0.valid}) }

    var body: some View { NavigationStack { Form {
        Section("Материал") { TextField("Название",text:$title); TextField("Описание (необязательно)",text:$description,axis:.vertical); TextField("Теги: химия, 9 класс, ОГЭ",text:$tags) }
        Section("Данные") { Button { importer=true } label:{Label(table == nil ? "Выбрать CSV / TSV":"Выбрать другой файл",systemImage:"doc.badge.plus")}; if let table { Text("\(table.rows.count) строк · \(table.headers.count) атрибутов").font(.caption).foregroundStyle(.secondary); preview(table) } }
        if let table { rulesSection(table) }; if let error { Text(error).foregroundStyle(.red) }
    }.navigationTitle("Создать материал").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement:.cancellationAction){Button("Отмена"){dismiss()}}; ToolbarItem(placement:.confirmationAction){Button("Сохранить"){save()}.disabled(!canSave)} }
      .fileImporter(isPresented:$importer,allowedContentTypes:[.commaSeparatedText,.tabSeparatedText,.plainText],allowsMultipleSelection:false,onCompletion:importFile)
    } }

    private func preview(_ t:ImportedTable)->some View { ScrollView(.horizontal){Grid(alignment:.leading){GridRow{ForEach(t.headers,id:\.self){Text($0).bold()}};ForEach(Array(t.rows.prefix(3).enumerated()),id:\.offset){_,row in GridRow{ForEach(Array(row.enumerated()),id:\.offset){_,v in Text(v).lineLimit(1)}}}}.font(.caption)} }

    @ViewBuilder private func rulesSection(_ t:ImportedTable)->some View {
        Section("Правила вопросов") { ForEach(rules.indices, id: \.self){ index in NavigationLink { QuestionRuleEditor(rule:$rules[index],headers:t.headers) } label:{VStack(alignment:.leading){Text(rules[index].template).lineLimit(1);Text("\(rules[index].answers.count) ответов · \(rules[index].answers.filter{$0.correct}.count) правильных").font(.caption).foregroundStyle(rules[index].valid ? Color.secondary : Color.red)}}}; Button { rules.append(DraftQuestionRule()) } label:{Label("Добавить правило вопроса",systemImage:"plus.circle.fill")} }
    }

    private func importFile(_ result:Result<[URL],Error>){do{guard let url=try result.get().first else{return};let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}};let data=try Data(contentsOf:url);guard let text=String(data:data,encoding:.utf8) ?? String(data:data,encoding:.windowsCP1251),let parsed=TableImportParser.parse(text) else{throw CocoaError(.fileReadCorruptFile)};table=parsed;rules=[];error=nil;if title.isEmpty{title=url.deletingPathExtension().lastPathComponent}}catch{self.error="Не удалось прочитать файл: \(error.localizedDescription)"}}
    private func save(){ guard let table, let first=rules.first(where:{$0.valid}), let answer=first.answers.first(where:{$0.correct}), let q=first.fields.first, let a=answer.fields.first else{return}; do { try store.saveCSV(title:title,subject:"",topic:tags,table:table,mappings:[CardMapping(from:q,to:a)]);dismiss() } catch { self.error="Не удалось сохранить: \(error.localizedDescription)" } }
}

private struct QuestionRuleEditor: View {
    @Binding var rule:DraftQuestionRule; let headers:[String]
    var body:some View { Form { Section("Вопрос") { FieldSelector(title:"Атрибуты вопроса",selection:$rule.fields,headers:headers); TextField("Шаблон, например: Что такое {1}?",text:$rule.template,axis:.vertical); Toggle("Показывать количество правильных ответов",isOn:$rule.showCorrectCount) }
        Section("Варианты ответов · 1–6") { ForEach(rule.answers.indices, id: \.self){ index in NavigationLink { AnswerEditor(answer:$rule.answers[index],headers:headers) } label:{HStack{Image(systemName:rule.answers[index].correct ? "checkmark.circle.fill":"circle").foregroundStyle(rule.answers[index].correct ? .green:.secondary);Text(rule.answers[index].template);Spacer()}} }.onDelete { rule.answers.remove(atOffsets:$0) }; if rule.answers.count<6 { Button { rule.answers.append(DraftAnswer()) } label:{Label("Добавить вариант ответа",systemImage:"plus.circle")} } }
        if !rule.valid { Section { Text("Для сохранения правила выберите атрибуты вопроса, создайте 1–6 заполненных вариантов и отметьте минимум один правильный.").font(.caption).foregroundStyle(.red) } }
    }.navigationTitle("Правило вопроса") }
}

private struct AnswerEditor:View { @Binding var answer:DraftAnswer;let headers:[String];var body:some View{Form{Section("Ответ"){FieldSelector(title:"Атрибуты ответа",selection:$answer.fields,headers:headers);TextField("Шаблон ответа, например: {1} — {2}",text:$answer.template,axis:.vertical);Toggle("Правильный ответ",isOn:$answer.correct)}}.navigationTitle("Вариант ответа")} }
private struct FieldSelector:View { let title:String;@Binding var selection:[Int];let headers:[String];var body:some View{VStack(alignment:.leading){Text(title).font(.caption).foregroundStyle(.secondary);ForEach(headers.indices,id:\.self){i in Toggle(isOn:Binding(get:{selection.contains(i)},set:{on in if on{selection.append(i)}else{selection.removeAll{$0==i}}})){Text("{\((selection.firstIndex(of:i) ?? 0)+1)}  \(headers[i])")}}}} }
