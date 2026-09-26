import SwiftUI

struct TableImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cards: [(String,String)]
    @State private var source = ""
    @State private var table: ImportedTable?
    @State private var mappings: Set<CardMapping> = []
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Вставь таблицу") {
                    Text("Скопируй диапазон вместе с заголовками из Excel, Numbers или Google Sheets.").font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $source).frame(minHeight: 150).font(.system(.body, design: .monospaced))
                    Button("Распознать таблицу") { parse() }.disabled(source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if let table { preview(table) }
                if let error { Section { Text(error).foregroundStyle(.red) } }
            }
            .navigationTitle("Импорт таблицы")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Добавить") { add() }.disabled(table == nil || mappings.isEmpty) }
            }
        }
    }

    @ViewBuilder private func preview(_ table: ImportedTable) -> some View {
        Section("Предпросмотр: \(table.rows.count) строк") {
            ScrollView(.horizontal) {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                    GridRow { ForEach(Array(table.headers.enumerated()), id: \.offset) { _, h in Text(h).bold() } }
                    ForEach(Array(table.rows.prefix(4).enumerated()), id: \.offset) { _, row in GridRow { ForEach(Array(row.enumerated()), id: \.offset) { _, v in Text(v).lineLimit(2) } } }
                }.font(.caption)
            }
        }
        Section("Что спрашивать") {
            ForEach(0..<table.headers.count, id: \.self) { from in
                ForEach(0..<table.headers.count, id: \.self) { to in
                    if from != to { mappingToggle(from: from, to: to, table: table) }
                }
            }
            Text("Будет создано \(TableImportParser.cards(table: table, mappings: mappings).count) карточек.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func mappingToggle(from: Int, to: Int, table: ImportedTable) -> some View {
        let mapping = CardMapping(from: from, to: to)
        return Toggle("\(table.headers[from]) → \(table.headers[to])", isOn: Binding(get: { mappings.contains(mapping) }, set: { on in if on { mappings.insert(mapping) } else { mappings.remove(mapping) } }))
    }
    private func parse() {
        guard let parsed = TableImportParser.parse(source) else { table=nil; mappings=[]; error="Не удалось распознать таблицу. Вставь минимум две строки с одинаковым числом столбцов."; return }
        table=parsed; error=nil; mappings=[]
        if parsed.headers.count >= 2 { mappings.insert(CardMapping(from:0,to:1)); mappings.insert(CardMapping(from:1,to:0)) }
        if parsed.headers.count == 4 {
            mappings.formUnion([
                CardMapping(from:2,to:3), CardMapping(from:3,to:2),
                CardMapping(from:0,to:2), CardMapping(from:2,to:0),
                CardMapping(from:1,to:3), CardMapping(from:3,to:1)
            ])
        }
    }
    private func add() { guard let table else { return }; cards.append(contentsOf: TableImportParser.cards(table: table, mappings: mappings)); dismiss() }
}
