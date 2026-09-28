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
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let firstLine = normalized.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first.map(String.init) ?? ""
        let delimiter: Character = firstLine.contains("\t") ? "\t" : (firstLine.contains(";") ? ";" : ",")
        guard let matrix = parseDelimited(normalized, delimiter: delimiter), matrix.count >= 2 else { return nil }
        let cleaned = matrix.filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } }
            .map { $0.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } }
        guard let width = cleaned.first?.count, width >= 2, cleaned.dropFirst().allSatisfy({ $0.count == width }) else { return nil }
        return ImportedTable(headers: cleaned[0], rows: Array(cleaned.dropFirst()))
    }

    private static func parseDelimited(_ text: String, delimiter: Character) -> [[String]]? {
        var rows = [[String]](), row = [String](), field = "", quoted = false
        var index = text.startIndex
        while index < text.endIndex {
            let c = text[index]
            if c == "\"" {
                let next = text.index(after: index)
                if quoted, next < text.endIndex, text[next] == "\"" { field.append("\""); index = next }
                else { quoted.toggle() }
            } else if c == delimiter && !quoted { row.append(field); field = "" }
            else if c == "\n" && !quoted { row.append(field); rows.append(row); row = []; field = "" }
            else { field.append(c) }
            index = text.index(after: index)
        }
        guard !quoted else { return nil }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }

    static func cards(table: ImportedTable, mappings: Set<CardMapping>) -> [(String, String)] {
        table.rows.flatMap { row in mappings.sorted { $0.id < $1.id }.compactMap { map in
            guard map.from < row.count, map.to < row.count, !row[map.from].isEmpty, !row[map.to].isEmpty else { return nil }
            let prompt = "\(table.headers[map.from]): \(row[map.from])\n\(table.headers[map.to])?"
            return (prompt, row[map.to])
        }}
    }
}
