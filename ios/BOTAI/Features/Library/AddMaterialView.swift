import SwiftUI
import UniformTypeIdentifiers
import ZIPFoundation

struct DraftAnswer: Identifiable, Hashable {
    let id = UUID(); var fields: [Int] = []; var template = ""; var correct = true
}
struct DraftQuestionRule: Identifiable, Hashable {
    let id = UUID(); var fields: [Int] = []; var template = ""; var showCorrectCount = false
    var answers: [DraftAnswer] = [DraftAnswer()]
    var valid: Bool { !fields.isEmpty && !template.isEmpty && (1...6).contains(answers.count) && answers.contains(where: { $0.correct }) && answers.allSatisfy { !$0.fields.isEmpty && !$0.template.isEmpty } }
}

struct AddMaterialView: View {
    var onSaved: (() -> Void)? = nil
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
            .fileImporter(isPresented: $importer, allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText, .zip], allowsMultipleSelection: false, onCompletion: importFile)
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
            Button { importer = true } label: { Label(table == nil ? "Выбрать CSV / TSV / ZIP" : "Заменить файл", systemImage: "doc.badge.plus").frame(maxWidth: .infinity).padding(.vertical, 7) }.buttonStyle(.borderedProminent).tint(.cyan)
            if let table {
                Button { withAnimation { dataExpanded.toggle() } } label: {
                    HStack { Text("\(table.rows.count) строк · \(table.headers.count) атрибута"); Spacer(); Image(systemName: dataExpanded ? "chevron.up" : "chevron.down") }
                }.foregroundStyle(.white.opacity(0.72))
                if dataExpanded { preview(table) }
            }
        }
    }

    private func preview(_ t: ImportedTable) -> some View {
        ScrollView(.horizontal) { Grid(alignment: .leading, horizontalSpacing: 18) { GridRow { ForEach(t.headers, id: \.self) { Text($0).bold().foregroundStyle(.cyan) } }; ForEach(Array(t.rows.prefix(3).enumerated()), id: \.offset) { _, row in GridRow { ForEach(Array(row.enumerated()), id: \.offset) { col, value in if t.mediaColumns.contains(col), let root=t.mediaRoot { VStack(alignment:.leading,spacing:4) { MediaPreview(title:t.headers[col],root:root,value:value); Text(value).font(.caption2).foregroundStyle(.white.opacity(0.45)).lineLimit(1) }.frame(width:170,alignment:.leading) } else { Text(value).lineLimit(1).frame(maxWidth:230,alignment:.leading) } } } } }.font(.caption).foregroundStyle(.white.opacity(0.75)) }
    }

    private func rulesView(_ table: ImportedTable) -> some View {
        VStack(spacing: 14) {
            HStack { Text("НАБОРЫ ВОПРОСОВ").font(.caption.bold()).foregroundStyle(.cyan); Spacer(); Text("\(rules.count)").foregroundStyle(.white.opacity(0.45)) }
            ForEach(Array(rules.enumerated()), id: \.element.id) { index, item in QuestionRuleCard(rule: binding(for: item.id), headers: table.headers, sample: table.rows.first ?? [], mediaRoot: table.mediaRoot, mediaColumns: table.mediaColumns, number: index + 1, canDelete: true) { removeRule(id: item.id) } }
            Button { withAnimation { rules.append(DraftQuestionRule()) } } label: { Label("Добавить набор вопросов", systemImage: "plus.circle.fill").frame(maxWidth: .infinity).padding(.vertical, 8) }.buttonStyle(.bordered).tint(.cyan)
        }
    }

    private func importZIP(_ url: URL) throws -> ImportedTable {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("botai-import-\(UUID().uuidString)", isDirectory:true);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);try FileManager.default.unzipItem(at:url,to:root)
        let files=(FileManager.default.enumerator(at:root,includingPropertiesForKeys:nil)?.allObjects as? [URL]) ?? [];guard let csv=files.first(where:{["csv","tsv"].contains($0.pathExtension.lowercased())}) else { throw CocoaError(.fileReadCorruptFile) };let data=try Data(contentsOf:csv);guard let text=String(data:data,encoding:.utf8) ?? String(data:data,encoding:.windowsCP1251),var parsed=TableImportParser.parse(text) else {throw CocoaError(.fileReadCorruptFile)};parsed.mediaRoot=root;let exts:Set<String>=["png","jpg","jpeg","webp","heic"];parsed.mediaColumns=Set(parsed.headers.indices.filter { col in parsed.rows.contains { row in col < row.count && exts.contains(URL(fileURLWithPath:row[col]).pathExtension.lowercased()) } });return parsed
    }

    private func resolveMediaURL(root: URL, value: String) -> URL? {
        let direct = root.appendingPathComponent(value)
        if FileManager.default.fileExists(atPath: direct.path) { return direct }
        let name = URL(fileURLWithPath: value).lastPathComponent
        let files = (FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL]) ?? []
        return files.first { $0.lastPathComponent == name }
    }

    private func binding(for id: UUID) -> Binding<DraftQuestionRule> {
        Binding(get: { rules.first(where: { $0.id == id }) ?? DraftQuestionRule() }, set: { value in if let i = rules.firstIndex(where: { $0.id == id }) { rules[i] = value } })
    }
    private func removeRule(id: UUID) { withAnimation { rules.removeAll { $0.id == id } } }

    private func importFile(_ result: Result<[URL], Error>) { do { guard let url = try result.get().first else { return }; let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }; if url.pathExtension.lowercased() == "zip" { table = try importZIP(url); rules=[]; error=nil; if title.isEmpty { title=url.deletingPathExtension().lastPathComponent } } else { let data = try Data(contentsOf: url); guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1251), let parsed = TableImportParser.parse(text) else { throw CocoaError(.fileReadCorruptFile) }; table = parsed; rules = []; error = nil; if title.isEmpty { title = url.deletingPathExtension().lastPathComponent } } } catch { self.error = "Не удалось прочитать файл: \(error.localizedDescription)" } }
    private func save() { guard let table, rules.contains(where: { $0.valid }) else { return }; do { try store.saveCSV(title: title, description: description, tags: tags, table: table, ruleDrafts: rules); if let onSaved { onSaved() } else { dismiss() } } catch { self.error = "Не удалось сохранить: \(error.localizedDescription)" } }
}

private struct QuestionRuleCard: View {
    @Binding var rule: DraftQuestionRule
    let headers: [String]; let sample: [String]; let mediaRoot: URL?; let mediaColumns: Set<Int>; let number: Int; let canDelete: Bool; let delete: () -> Void
    var body: some View {
        BuilderCard(title: "ВОПРОС \(number)", icon: "questionmark.bubble.fill") {
            HStack { Spacer(); if canDelete { Button(role: .destructive, action: delete) { Label("Удалить вопрос", systemImage: "trash") }.font(.caption) } }
            TemplateEditor(label: "ВОПРОС", template: $rule.template, fields: $rule.fields, headers: headers, sample: sample, mediaRoot: mediaRoot, mediaColumns: mediaColumns)
            Divider().overlay(.white.opacity(0.12))
            HStack { Text("ОТВЕТЫ").font(.caption.bold()).foregroundStyle(.cyan); Spacer() }
            ForEach(rule.answers) { item in AnswerCard(answer: answerBinding(for: item.id), headers: headers, sample: sample, mediaRoot: mediaRoot, mediaColumns: mediaColumns, canDelete: true) { removeAnswer(id: item.id) } }
            if rule.answers.count < 6 { Button { withAnimation { rule.answers.append(DraftAnswer(correct: false)) } } label: { Label("Добавить ответ", systemImage: "plus").frame(maxWidth: .infinity) }.buttonStyle(.bordered).tint(.cyan) }
            if rule.answers.count > 1 { Toggle(isOn: $rule.showCorrectCount) { VStack(alignment: .leading, spacing: 2) { Text("Показывать количество правильных ответов").font(.subheadline.weight(.semibold)).foregroundStyle(.white); Text("Например: «Выберите 2 правильных ответа»").font(.caption).foregroundStyle(.white.opacity(0.65)) } }.tint(.cyan) }
            if !rule.valid { Text("Нужен минимум один заполненный правильный ответ.").font(.caption).foregroundStyle(.orange) }
        }
    }
    private func answerBinding(for id: UUID) -> Binding<DraftAnswer> { Binding(get: { rule.answers.first(where: { $0.id == id }) ?? DraftAnswer() }, set: { value in if let i = rule.answers.firstIndex(where: { $0.id == id }) { rule.answers[i] = value } }) }
    private func removeAnswer(id: UUID) { withAnimation { rule.answers.removeAll { $0.id == id } } }
}

private struct AnswerCard: View {
    @Binding var answer: DraftAnswer
    let headers: [String]; let sample: [String]; let mediaRoot: URL?; let mediaColumns: Set<Int>; let canDelete: Bool; let delete: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack { Button { answer.correct.toggle() } label: { Image(systemName: answer.correct ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(answer.correct ? .green : .white.opacity(0.4)) }; Text(answer.correct ? "Правильный ответ" : "Вариант ответа").font(.caption.bold()).foregroundStyle(.white.opacity(0.7)); Spacer(); if canDelete { Button(role: .destructive, action: delete) { Image(systemName: "trash") } } }
            TemplateEditor(label: nil, template: $answer.template, fields: $answer.fields, headers: headers, sample: sample, mediaRoot: mediaRoot, mediaColumns: mediaColumns)
        }.padding(12).background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(answer.correct ? Color.green.opacity(0.45) : Color.white.opacity(0.08)))
    }
}

private struct TemplateEditor: View {
    let label: String?; @Binding var template: String; @Binding var fields: [Int]; let headers: [String]; let sample: [String]; let mediaRoot: URL?; let mediaColumns: Set<Int>
    var body: some View { VStack(alignment: .leading, spacing: 9) {
        if let label { Text(label).font(.caption.bold()).foregroundStyle(.cyan) }
        TextField("Шаблон", text: $template, axis: .vertical).lineLimit(3...8).textInputAutocapitalization(.sentences).padding(12).background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 13)).foregroundStyle(.white)
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing:6) { ForEach(["×","÷","±","≈","≠","≤","≥","√","π","∞","°","→","⇄","Δ","Σ","²","³","₁","₂","₃","₄","₅","₆","₇","₈","₉","₀"], id: \.self) { symbol in Button(symbol) { template += symbol }.font(.subheadline.bold()).foregroundStyle(.white).frame(minWidth:30,minHeight:30).background(.white.opacity(0.08),in:RoundedRectangle(cornerRadius:8)) } } }
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 7) { ForEach(headers.indices, id: \.self) { i in Button { addField(i) } label: { Label(headers[i], systemImage: isMedia(i) ? "photo" : "plus").font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 7).background(.cyan.opacity(0.13), in: Capsule()).overlay(Capsule().stroke(.cyan.opacity(0.35))) }.foregroundStyle(.cyan) } } }
        if !fields.isEmpty { VStack(alignment: .leading, spacing: 7) { Text("ПРИМЕР").font(.caption2.bold()).foregroundStyle(.white.opacity(0.4)); Text(renderedText).foregroundStyle(.white.opacity(0.8)).font(.subheadline); ForEach(fields.filter { mediaColumns.contains($0) }, id: \.self) { i in if i < sample.count, let root=mediaRoot { MediaPreview(title: headers[i], root: root, value: sample[i]) } } } }
    } }
    private func isMedia(_ i:Int) -> Bool { mediaColumns.contains(i) }
    private func addField(_ i: Int) { if let pos = fields.firstIndex(of: i) { template += "{\(pos + 1)}" } else { fields.append(i); template += "{\(fields.count)}" } }
    private var renderedText: String { var result = template; for (position, field) in fields.enumerated() where field < sample.count { result = result.replacingOccurrences(of: "{\(position + 1)}", with: mediaColumns.contains(field) ? "[\(headers[field])]" : sample[field]) }; return result }
}

private struct MediaPreview: View {
    let title: String; let root: URL; let value: String
    private var url: URL? { let direct=root.appendingPathComponent(value);if FileManager.default.fileExists(atPath:direct.path){return direct};let name=URL(fileURLWithPath:value).lastPathComponent;let files=(FileManager.default.enumerator(at:root,includingPropertiesForKeys:nil)?.allObjects as? [URL]) ?? [];return files.first{$0.lastPathComponent==name} }
    var body: some View { VStack(alignment:.leading,spacing:5){ Text(title).font(.caption2.bold()).foregroundStyle(.cyan);if let url,let ui=UIImage(contentsOfFile:url.path){Image(uiImage:ui).resizable().scaledToFit().frame(maxHeight:150).clipShape(RoundedRectangle(cornerRadius:10))}else{Label("Изображение недоступно",systemImage:"photo.badge.exclamationmark").font(.caption).foregroundStyle(.orange)} }.padding(7).background(.black.opacity(0.2),in:RoundedRectangle(cornerRadius:12)) }
}

private struct BuilderTextField: View { let title: String; @Binding var text: String; var hint: String? = nil; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title.uppercased()).font(.caption2.bold()).foregroundStyle(.white.opacity(0.45)); TextField(hint ?? title, text: $text, axis: .vertical).padding(11).background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white) } } }
private struct BuilderCard<Content: View>: View { let title: String; let icon: String; @ViewBuilder let content: Content; init(title: String, icon: String, @ViewBuilder content: () -> Content) { self.title=title; self.icon=icon; self.content=content() }; var body: some View { VStack(alignment: .leading, spacing: 12) { Label(title, systemImage: icon).font(.caption.bold()).foregroundStyle(.cyan); content }.padding(15).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 19)).overlay(RoundedRectangle(cornerRadius: 19).stroke(.cyan.opacity(0.22))) } }
private struct BuilderBackground: View { var body: some View { ZStack { LinearGradient(colors:[Color(red:0.015,green:0.035,blue:0.12),Color(red:0.03,green:0.08,blue:0.18),.black],startPoint:.top,endPoint:.bottom).ignoresSafeArea(); Canvas { c,s in for x in stride(from:0.0,through:s.width,by:32){var p=Path();p.move(to:.init(x:x,y:0));p.addLine(to:.init(x:x,y:s.height));c.stroke(p,with:.color(.cyan.opacity(0.035)))};for y in stride(from:0.0,through:s.height,by:32){var p=Path();p.move(to:.init(x:0,y:y));p.addLine(to:.init(x:s.width,y:y));c.stroke(p,with:.color(.cyan.opacity(0.035)))}}.ignoresSafeArea() } } }
