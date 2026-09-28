import Foundation
import Observation

@MainActor @Observable
final class MaterialStore {
    private(set) var materials: [StudyMaterialRecord] = []
    private let repository: MaterialRepository?

    init(repository: MaterialRepository? = nil) {
        self.repository = repository
        refresh()
    }

    func refresh() { materials = (try? repository?.materials()) ?? [] }

    func saveCSV(title: String, subject: String, topic: String, table: ImportedTable, mappings: Set<CardMapping>) throws {
        guard let repository else { return }
        let materialID = UUID(); let now = Date()
        let fields = table.headers.enumerated().map { index, title in MaterialField(id: UUID(), materialID: materialID, key: "f\(index)", title: title, position: index) }
        let rows = table.rows.enumerated().map { position, row in KnowledgeRow(id: UUID(), materialID: materialID, position: position, values: Dictionary(uniqueKeysWithValues: row.enumerated().map { ("f\($0.offset)", $0.element) })) }
        let rules = mappings.map { QuestionRule(id: UUID(), materialID: materialID, kind: .card, promptFieldKey: "f\($0.from)", answerFieldKey: "f\($0.to)", enabled: true) }
        let material = StudyMaterialRecord(id: materialID, title: title, subject: subject.nilIfBlank, topic: topic.nilIfBlank, kind: .reference, source: .created, createdAt: now, updatedAt: now)
        try repository.save(material: material, fields: fields, rows: rows, rules: rules); refresh()
    }
}

private extension String { var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self } }
