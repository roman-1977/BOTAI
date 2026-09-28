import SwiftUI
import UniformTypeIdentifiers

struct DraftAnswer: Identifiable, Hashable {
    let id = UUID(); var fields: [Int] = []; var template = ""; var correct = true
}
struct DraftQuestionRule: Identifiable, Hashable {
    let id = UUID(); var fields: [Int] = []; var template = ""; var showCorrectCount = false
    var answers: [DraftAnswer] = [DraftAnswer()]
    var valid: Bool { !fields.isEmpty && !template.isEmpty && (1...6).contains(answers.count) && answers.contains(where: { $0.correct }) && answers.allSatisfy { !$0.fields.isEmpty && !$0.template.isEmpty } }
}

struct AddMaterialView: View {
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var importer = false
    @State private var table: ImportedTable?
    @State private var title = ""
    @State private var description = ""
    @State private var tags = ""
    @State private var rules: [DraftQuestionRule] = []
    @State private var error: String?
    @State private var dataExpanded = false

    private var canSave: Bool {
        table != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && rules.contains(where: { $0.valid })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BuilderBackground()
                ScrollView { VStack(spacing: 16) { materialCard; dataCard; if let table { rulesView(table) }; if let error { Text(error).foregroundStyle(.red) } }.padding(16) }
            }
            .navigationTitle("Создать материал").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Сохранить") { save() }.disabled(!canSave) }
            }
            .fileImporter(isPresented: $importer, allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText], allowsMultipleSelection: false, onCompletion: importFile)
        }
    }

    private var materialCard: some View {
        BuilderCard(title: "МАТЕРИАЛ", icon: "square.stack.3d.up.fill") {
            BuilderTextField(title: "Название", text: $title)
            BuilderTextField(title: "Описание", text: $description)
            BuilderTextField(title: "Теги", text: $tags, hint: "химия, 9 класс, ОГЭ")
        }
    }

    private var dataCard: some View {
        BuilderCard(title: "ИСХОДНЫЕ ДАННЫЕ", icon: "tablecells.fill") {
            Button { importer = true } label: { Label(table == nil ? "Выбрать CSV / TSV" : "Заменить файл", systemImage: "doc.badge.plus") }.buttonStyle(.borderedProminent).tint(.cyan)
            if let table {
                Button { withAnimation { dataExpanded.toggle() } } label: {
                    HStack { Text("\(table.rows.count) строк · \(table.headers.count) атрибута"); Spacer(); Image(systemName: dataExpanded ? "chevron.up" : "chevron.down") }
                }.foregroundStyle(.white.opacity(0.72))
                if dataExpanded { preview(table) }
            }
        }
    }

    private func preview(_ t: ImportedTable) -> some View {
        ScrollView(.horizontal) { Grid(alignment: .leading, horizontalSpacing: 18) { GridRow { ForEach(t.headers, id: \.self) { Text($0).bold().foregroundStyle(.cyan) } }; ForEach(Array(t.rows.prefix(3).enumerated()), id: \.offset) { _, row in GridRow { ForEach(Array(row.enumerated()), id: \.offset) { _, value in Text(value).lineLimit(1).frame(maxWidth: 230, alignment: .leading) } } } }.font(.caption).foregroundStyle(.white.opacity(0.75)) }
    }

    private func rulesView(_ table: ImportedTable) -> some View {
        VStack(spacing: 14) {
            HStack { Text("ПРАВИЛА ВОПРОСОВ").font(.caption.bold()).foregroundStyle(.cyan); Spacer(); Text("\(rules.count)").foregroundStyle(.white.opacity(0.45)) }
            ForEach(rules.indices, id: \.self) { index in QuestionRuleCard(rule: $rules[index], headers: table.headers, sample: table.rows.first ?? [], number: index + 1, canDelete: true) { rules.remove(at: index) } }
            Button { withAnimation { rules.append(DraftQuestionRule()) } } label: { Label("Добавить правило вопроса", systemImage: "plus.circle.fill").frame(maxWidth: .infinity).padding(.vertical, 8) }.buttonStyle(.bordered).tint(.cyan)
        }
    }

    private func importFile(_ result: Result<[URL], Error>) { do { guard let url = try result.get().first else { return }; let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; let data = try Data(contentsOf: url); guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1251), let parsed = TableImportParser.parse(text) else { throw CocoaError(.fileReadCorruptFile) }; table = parsed; rules = []; error = nil; if title.isEmpty { title = url.deletingPathExtension().lastPathComponent } } catch { self.error = "Не удалось прочитать файл: \(error.localizedDescription)" } }
    private func save() { guard let table, let first = rules.first(where: { $0.valid }), let answer = first.answers.first(where: { $0.correct }), let q = first.fields.first, let a = answer.fields.first else { return }; do { try store.saveCSV(title: title, subject: "", topic: tags, table: table, mappings: [CardMapping(from: q, to: a)]); dismiss() } catch { self.error = "Не удалось сохранить: \(error.localizedDescription)" } }
}

private struct QuestionRuleCard: View {
    @Binding var rule: DraftQuestionRule
    let headers: [String]; let sample: [String]; let number: Int; let canDelete: Bool; let delete: () -> Void
    var body: some View {
        BuilderCard(title: "ВОПРОС \(number)", icon: "questionmark.bubble.fill") {
            HStack { Spacer(); if canDelete { Button(role: .destructive, action: delete) { Label("Удалить вопрос", systemImage: "trash") }.font(.caption) } }
            TemplateEditor(label: "ВОПРОС", template: $rule.template, fields: $rule.fields, headers: headers, sample: sample)
            Divider().overlay(.white.opacity(0.12))
            HStack { Text("ОТВЕТЫ").font(.caption.bold()).foregroundStyle(.cyan); Spacer() }
            Toggle("Показывать количество правильных ответов", isOn: $rule.showCorrectCount).font(.subheadline).tint(.cyan)
            ForEach(rule.answers.indices, id: \.self) { index in AnswerCard(answer: $rule.answers[index], headers: headers, sample: sample, canDelete: true) { rule.answers.remove(at: index) } }
            if rule.answers.count < 6 { Button { withAnimation { rule.answers.append(DraftAnswer(correct: false)) } } label: { Label("Добавить ответ", systemImage: "plus").frame(maxWidth: .infinity) }.buttonStyle(.bordered).tint(.cyan) }
            if !rule.valid { Text("Нужен минимум один заполненный правильный ответ.").font(.caption).foregroundStyle(.orange) }
        }
    }
}

private struct AnswerCard: View {
    @Binding var answer: DraftAnswer
    let headers: [String]; let sample: [String]; let canDelete: Bool; let delete: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Button { answer.correct.toggle() } label: { Image(systemName: answer.correct ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(answer.correct ? .green : .white.opacity(0.4)) }; Text(answer.correct ? "Правильный ответ" : "Вариант ответа").font(.caption.bold()).foregroundStyle(.white.opacity(0.7)); Spacer(); if canDelete { Button(role: .destructive, action: delete) { Image(systemName: "trash") } } }
            TemplateEditor(label: nil, template: $answer.template, fields: $answer.fields, headers: headers, sample: sample)
        }.padding(12).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(answer.correct ? Color.green.opacity(0.45) : Color.white.opacity(0.08)))
    }
}

private struct TemplateEditor: View {
    let label: String?; @Binding var template: String; @Binding var fields: [Int]; let headers: [String]; let sample: [String]
    var body: some View { VStack(alignment: .leading, spacing: 9) {
        if let label { Text(label).font(.caption.bold()).foregroundStyle(.cyan) }
        TextField("Шаблон", text: $template, axis: .vertical).lineLimit(2...4).padding(12).background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 13)).foregroundStyle(.white)
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 7) { ForEach(headers.indices, id: \.self) { i in Button { addField(i) } label: { Text("+ \(headers[i])").font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 7).background(.cyan.opacity(0.13), in: Capsule()).overlay(Capsule().stroke(.cyan.opacity(0.35))) }.foregroundStyle(.cyan) } } }
        if !fields.isEmpty { VStack(alignment: .leading, spacing: 3) { Text("ПРИМЕР").font(.caption2.bold()).foregroundStyle(.white.opacity(0.4)); Text(rendered).foregroundStyle(.white.opacity(0.8)).font(.subheadline) } }
    } }
    private func addField(_ i: Int) { if let pos = fields.firstIndex(of: i) { template += "{\(pos + 1)}" } else { fields.append(i); template += "{\(fields.count)}" } }
    private var rendered: String { var result = template; for (position, field) in fields.enumerated() where field < sample.count { result = result.replacingOccurrences(of: "{\(position + 1)}", with: sample[field]) }; return result }
}

private struct BuilderTextField: View { let title: String; @Binding var text: String; var hint: String? = nil; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(.white.opacity(0.45)); TextField(hint ?? title, text: $text, axis: .vertical).padding(11).background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white) } } }
private struct BuilderCard<Content: View>: View { let title: String; let icon: String; @ViewBuilder let content: Content; init(title: String, icon: String, @ViewBuilder content: () -> Content) { self.title=title; self.icon=icon; self.content=content() }; var body: some View { VStack(alignment: .leading, spacing: 12) { Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(.cyan); content }.padding(15).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 19)).overlay(RoundedRectangle(cornerRadius: 19).stroke(.cyan.opacity(0.22))) } }
private struct BuilderBackground: View { var body: some View { ZStack { LinearGradient(colors:[Color(red:0.015,green:0.035,blue:0.12),Color(red:0.03,green:0.08,blue:0.18),.black],startPoint:.top,endPoint:.bottom).ignoresSafeArea(); Canvas { c,s in for x in stride(from:0.0,through:s.width,by:32){var p=Path();p.move(to:.init(x:x,y:0));p.addLine(to:.init(x:x,y:s.height));c.stroke(p,with:.color(.cyan.opacity(0.035)))};for y in stride(from:0.0,through:s.height,by:32){var p=Path();p.move(to:.init(x:0,y:y));p.addLine(to:.init(x:s.width,y:y));c.stroke(p,with:.color(.cyan.opacity(0.035)))}}.ignoresSafeArea() } } }
