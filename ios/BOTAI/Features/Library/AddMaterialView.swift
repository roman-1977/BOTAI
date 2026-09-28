import SwiftUI
import UniformTypeIdentifiers

struct AddMaterialView: View {
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var importer = false
    @State private var source = ""; @State private var table: ImportedTable?; @State private var mappings: Set<CardMapping> = []
    @State private var title = ""; @State private var subject = ""; @State private var topic = ""; @State private var error: String?

    var body: some View { NavigationStack { Form {
        Section("Материал") { TextField("Название", text: $title); TextField("Предмет", text: $subject); TextField("Тема", text: $topic) }
        Section("CSV / TSV") { Button { importer = true } label: { Label("Выбрать файл", systemImage: "doc.badge.plus") }; Text("Первая строка — названия столбцов. Поддерживаются UTF-8 CSV, TSV и разделитель ;").font(.caption).foregroundStyle(.secondary) }
        if let table { preview(table) }; if let error { Text(error).foregroundStyle(.red) }
    }.navigationTitle("Создать материал").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Сохранить") { save() }.disabled(table == nil || mappings.isEmpty || title.trimmingCharacters(in:.whitespaces).isEmpty) } }
        .fileImporter(isPresented: $importer, allowedContentTypes: [.commaSeparatedText,.tabSeparatedText,.plainText], allowsMultipleSelection: false, onCompletion: importFile)
    } }

    @ViewBuilder private func preview(_ t: ImportedTable) -> some View {
        Section("Предпросмотр · \(t.rows.count) строк") { ScrollView(.horizontal) { Grid(alignment:.leading) { GridRow { ForEach(t.headers,id:\.self){Text($0).bold()} }; ForEach(Array(t.rows.prefix(4).enumerated()),id:\.offset){_,row in GridRow { ForEach(Array(row.enumerated()),id:\.offset){_,v in Text(v)} } } }.font(.caption) } }
        Section("Правила вопросов") {
            ForEach(allMappings(for: t), id: \.id) { mapping in
                mappingToggle(mapping, table: t)
            }
            Text("Получится \(TableImportParser.cards(table: t, mappings: mappings).count) карточек")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func allMappings(for table: ImportedTable) -> [CardMapping] {
        (0..<table.headers.count).flatMap { from in
            (0..<table.headers.count).compactMap { to in from == to ? nil : CardMapping(from: from, to: to) }
        }
    }

    private func mappingToggle(_ mapping: CardMapping, table: ImportedTable) -> some View {
        Toggle("\(table.headers[mapping.from]) → \(table.headers[mapping.to])", isOn: Binding(
            get: { mappings.contains(mapping) },
            set: { enabled in if enabled { mappings.insert(mapping) } else { mappings.remove(mapping) } }
        ))
    }

    private func importFile(_ result: Result<[URL],Error>) { do { guard let url=try result.get().first else{return}; let access=url.startAccessingSecurityScopedResource(); defer{if access{url.stopAccessingSecurityScopedResource()}}; let data=try Data(contentsOf:url); guard let text=String(data:data,encoding:.utf8) ?? String(data:data,encoding:.windowsCP1251), let parsed=TableImportParser.parse(text) else{throw CocoaError(.fileReadCorruptFile)}; source=text; table=parsed; error=nil; mappings=[]; if parsed.headers.count>1 { mappings=[CardMapping(from:0,to:1),CardMapping(from:1,to:0)] }; if title.isEmpty { title=url.deletingPathExtension().lastPathComponent } } catch { self.error="Не удалось прочитать файл: \(error.localizedDescription)" } }
    private func save(){guard let table else{return};do{try store.saveCSV(title:title,subject:subject,topic:topic,table:table,mappings:mappings);dismiss()}catch{self.error="Не удалось сохранить: \(error.localizedDescription)"}}
}
