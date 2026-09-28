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

    func importPackage(_ url: URL, title overrideTitle: String? = nil) throws {
        let p=try BOTAIPackageService.read(url);try importPackagePayload(p,title:overrideTitle)
    }

    func importPackagePayload(_ p: BOTAIPackagePayload, title overrideTitle: String? = nil) throws {
        guard let repository else { return };let id=UUID(),now=Date();let mediaDir=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask).first!.appendingPathComponent("BOTAI/Media/\(id.uuidString)",isDirectory:true);try FileManager.default.createDirectory(at:mediaDir,withIntermediateDirectories:true)
        let fields=p.manifest.fields.map{MaterialField(id:UUID(),materialID:id,key:$0.key,title:$0.title,position:$0.position)};let imageKeys=Set(p.manifest.fields.filter{$0.type=="image"}.map(\.key))
        let rows=try p.manifest.rows.enumerated().map{pos,row in var v=row;for key in imageKeys {if let rel=v[key]{let src=p.root.appendingPathComponent(rel);if FileManager.default.fileExists(atPath:src.path){let dst=mediaDir.appendingPathComponent(src.lastPathComponent);try FileManager.default.copyItem(at:src,to:dst);v[key]=dst.path}}};return KnowledgeRow(id:UUID(),materialID:id,position:pos,values:v)}
        let rules=p.manifest.questionSets.map{q in let kind=q.kind;return QuestionRule(id:UUID(),materialID:id,kind:kind,promptFieldKey:q.promptFieldKeys.first ?? "",answerFieldKey:q.answers.first?.fieldKeys.first ?? "",promptTemplate:q.promptTemplate,promptFieldKeys:q.promptFieldKeys,answers:q.answers,showCorrectCount:q.showCorrectCount,enabled:q.enabled)}
        let m=StudyMaterialRecord(id:id,title:overrideTitle ?? p.manifest.title,subject:nil,topic:p.manifest.tags,description:p.manifest.description,kind:p.manifest.kind,source:.importedPackage,createdAt:now,updatedAt:now);try repository.save(material:m,fields:fields,rows:rows,rules:rules);refresh()
    }

    func exportPackage(id: UUID) throws -> URL { guard let repository,let c=try repository.content(id:id) else { throw CocoaError(.fileNoSuchFile) };return try BOTAIPackageService.write(c) }

    func delete(id: UUID) throws {
        guard let repository else { return }
        try repository.delete(id: id)
        refresh()
    }
}

private extension String { var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self } }
