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

    func saveCSV(title: String, description: String = "", tags: String = "", table: ImportedTable, ruleDrafts: [DraftQuestionRule]? = nil, mappings: Set<CardMapping> = []) throws {
        guard let repository else { return }
        let materialID = UUID(); let now = Date()
        let fields = table.headers.enumerated().map { index, title in MaterialField(id: UUID(), materialID: materialID, key: "f\(index)", title: title, position: index) }
        let rows = table.rows.enumerated().map { position, row in KnowledgeRow(id: UUID(), materialID: materialID, position: position, values: Dictionary(uniqueKeysWithValues: row.enumerated().map { ("f\($0.offset)", $0.element) })) }
        let rules: [QuestionRule] = ruleDrafts?.filter(\.valid).map { d in
            let answers=d.answers.map { QuestionAnswerRule(template:$0.template,fieldKeys:$0.fields.map{"f\($0)"},correct:$0.correct) };let pk=d.fields.first.map{"f\($0)"} ?? "f0";let ak=d.answers.first?.fields.first.map{"f\($0)"} ?? "f0"
            return QuestionRule(id:UUID(),materialID:materialID,kind:d.answers.count > 1 ? (d.answers.filter(\.correct).count > 1 ? .multipleChoice:.singleChoice):.card,promptFieldKey:pk,answerFieldKey:ak,promptTemplate:d.template,promptFieldKeys:d.fields.map{"f\($0)"},answers:answers,showCorrectCount:d.showCorrectCount,enabled:true)
        } ?? mappings.map { QuestionRule(id: UUID(), materialID: materialID, kind: .card, promptFieldKey: "f\($0.from)", answerFieldKey: "f\($0.to)", enabled: true) }
        let material = StudyMaterialRecord(id: materialID, title: title, subject: nil, topic: tags.nilIfBlank, description: description.nilIfBlank, kind: .reference, source: .created, createdAt: now, updatedAt: now)
        try repository.save(material: material, fields: fields, rows: rows, rules: rules); refresh()
    }

    func content(id: UUID) -> MaterialContent? { try? repository?.content(id: id) }
}

private extension String { var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self } }
