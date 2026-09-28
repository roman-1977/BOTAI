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
        let mediaDir = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask).first!.appendingPathComponent("BOTAI/Media/\(materialID.uuidString)",isDirectory:true)
        if table.mediaRoot != nil { try FileManager.default.createDirectory(at:mediaDir,withIntermediateDirectories:true) }
        let rows = try table.rows.enumerated().map { position, row in
            var values:[String:String]=[:]
            for (index,value) in row.enumerated() { if table.mediaColumns.contains(index),let root=table.mediaRoot { let direct=root.appendingPathComponent(value);let name=URL(fileURLWithPath:value).lastPathComponent;let files=(FileManager.default.enumerator(at:root,includingPropertiesForKeys:nil)?.allObjects as? [URL]) ?? [];let src=FileManager.default.fileExists(atPath:direct.path) ? direct : files.first{$0.lastPathComponent==name};if let src{let dst=mediaDir.appendingPathComponent(name);if !FileManager.default.fileExists(atPath:dst.path){try FileManager.default.copyItem(at:src,to:dst)};values["f\(index)"]=dst.path}else{values["f\(index)"]=value} } else { values["f\(index)"]=value } }
            return KnowledgeRow(id:UUID(),materialID:materialID,position:position,values:values)
        }
        let rules: [QuestionRule] = ruleDrafts?.filter(\.valid).map { d in
            let answers=d.answers.map { QuestionAnswerRule(template:$0.template,fieldKeys:$0.fields.map{"f\($0)"},correct:$0.correct) };let pk=d.fields.first.map{"f\($0)"} ?? "f0";let ak=d.answers.first?.fields.first.map{"f\($0)"} ?? "f0"
            return QuestionRule(id:UUID(),materialID:materialID,kind:d.answers.count > 1 ? (d.answers.filter(\.correct).count > 1 ? .multipleChoice:.singleChoice):.card,promptFieldKey:pk,answerFieldKey:ak,promptTemplate:d.template,promptFieldKeys:d.fields.map{"f\($0)"},answers:answers,showCorrectCount:d.showCorrectCount,enabled:true)
        } ?? mappings.map { QuestionRule(id: UUID(), materialID: materialID, kind: .card, promptFieldKey: "f\($0.from)", answerFieldKey: "f\($0.to)", enabled: true) }
        let material = StudyMaterialRecord(id: materialID, title: title, subject: nil, topic: tags.nilIfBlank, description: description.nilIfBlank, kind: .reference, source: .created, createdAt: now, updatedAt: now)
        try repository.save(material: material, fields: fields, rows: rows, rules: rules); refresh()
    }

    func content(id: UUID) -> MaterialContent? { try? repository?.content(id: id) }

    func delete(id: UUID) throws {
        guard let repository else { return }
        try repository.delete(id: id)
        refresh()
    }
}

private extension String { var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self } }
