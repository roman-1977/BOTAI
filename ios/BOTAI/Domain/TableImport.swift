import Foundation

struct ImportedTable: Sendable {
    let headers: [String]
    let rows: [[String]]
}

struct ImportedCard: Sendable, Equatable {
    let prompt: String
    let answer: String
    let context: String?
}

struct CardMapping: Identifiable, Hashable, Sendable {
    let from: Int
    let to: Int
    var id: String { "\(from)-\(to)" }
}

enum TableImportParser {
    static func parse(_ source: String) -> ImportedTable? {
        let lines = source.split(whereSeparator: \.isNewline).map(String.init).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 2 else { return nil }
        let delimiter: Character = lines[0].contains("\t") ? "\t" : (lines[0].contains(";") ? ";" : ",")
        let matrix = lines.map { line in line.split(separator: delimiter, omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
        guard let width = matrix.first?.count, width >= 2, matrix.dropFirst().allSatisfy({ $0.count == width }) else { return nil }
        return ImportedTable(headers: matrix[0], rows: Array(matrix.dropFirst()))
    }

    static func cards(table: ImportedTable, mappings: Set<CardMapping>) -> [(String, String)] {
        table.rows.flatMap { row in mappings.sorted { $0.id < $1.id }.compactMap { map in
            guard map.from < row.count, map.to < row.count, !row[map.from].isEmpty, !row[map.to].isEmpty else { return nil }
            let prompt = "\(table.headers[map.from]): \(row[map.from])\n\(table.headers[map.to])?"
            return (prompt, row[map.to])
        }}
    }
}
