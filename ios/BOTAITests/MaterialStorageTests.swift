import Foundation
import Testing
@testable import BOTAI

struct MaterialStorageTests {
    @Test func materialRoundTripAndCascadeDelete() throws {
        let db = try AppDatabase()
        let repo = MaterialRepository(database: db)
        let id = UUID(), now = Date()
        let material = StudyMaterialRecord(id: id, title: "Кислоты", subject: "Химия", topic: "Кислоты", kind: .reference, source: .created, createdAt: now, updatedAt: now)
        let fields = [MaterialField(id: UUID(), materialID: id, key: "name", title: "Название", position: 0), MaterialField(id: UUID(), materialID: id, key: "formula", title: "Формула", position: 1)]
        let rows = [KnowledgeRow(id: UUID(), materialID: id, position: 0, values: ["name":"Серная кислота","formula":"H₂SO₄"])]
        let rules = [QuestionRule(id: UUID(), materialID: id, kind: .card, promptFieldKey: "name", answerFieldKey: "formula", enabled: true)]
        try repo.save(material: material, fields: fields, rows: rows, rules: rules)
        #expect(try repo.materials().map(\.id) == [id])
        try repo.delete(id: id)
        #expect(try repo.materials().isEmpty)
    }

    @Test func packageManifestDecodes() throws {
        let data = #"{"formatVersion":1,"title":"Test","subject":"Химия","topic":"Кислоты","kind":"reference","dataFile":"content.csv","rules":[{"kind":"card","from":"A","to":"B"}]}"#.data(using:.utf8)!
        let manifest = try JSONDecoder().decode(BOTAIPackageManifest.self, from: data)
        #expect(manifest.formatVersion == 1)
        #expect(manifest.rules.first?.from == "A")
    }
}
