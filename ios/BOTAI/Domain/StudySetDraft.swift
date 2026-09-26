import Foundation

struct StudySetDraft: Sendable {
    var headers: [String] = ["Вопрос", "Ответ"]
    var rows: [[String]] = []
    var mappings: Set<CardMapping> = [CardMapping(from: 0, to: 1)]

    var cards: [(String, String)] {
        TableImportParser.cards(table: ImportedTable(headers: headers, rows: rows), mappings: mappings)
    }
}
