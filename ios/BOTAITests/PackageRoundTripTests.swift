import Foundation
import Testing
@testable import BOTAI

struct PackageRoundTripTests {
    @Test func exportsAndImportsPackageWithRealImageBytes() throws {
        let fm = FileManager.default
        let materialID = UUID()
        let mediaDir = MaterialMediaStore.directory(for: materialID)
        try fm.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: mediaDir) }
        let imageBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4])
        let imageURL = mediaDir.appendingPathComponent("example.png")
        try imageBytes.write(to: imageURL)

        let now = Date()
        let material = StudyMaterialRecord(id: materialID, title: "Package round trip", subject: nil, topic: "QA", kind: .reference, source: .created, createdAt: now, updatedAt: now)
        let fields = [
            MaterialField(id: UUID(), materialID: materialID, key: "name", title: "Name", position: 0),
            MaterialField(id: UUID(), materialID: materialID, key: "picture", title: "Picture", position: 1)
        ]
        let rows = [KnowledgeRow(id: UUID(), materialID: materialID, position: 0, values: [
            "name": "Example",
            "picture": MaterialMediaStore.reference(materialID: materialID, fileName: "example.png")
        ])]
        let rules = [QuestionRule(id: UUID(), materialID: materialID, kind: .card, promptFieldKey: "name", answerFieldKey: "picture", promptFieldKeys: ["name"], answers: [QuestionAnswerRule(template: "{1}", fieldKeys: ["picture"], correct: true)], enabled: true)]
        let content = MaterialContent(material: material, fields: fields, rows: rows, rules: rules)
        let exported = try BOTAIPackageService.write(content)
        defer { try? fm.removeItem(at: exported) }
        let payload = try BOTAIPackageService.read(exported)
        defer { try? fm.removeItem(at: payload.root) }

        #expect(payload.manifest.title == material.title)
        #expect(payload.manifest.rows.count == 1)
        #expect(payload.manifest.questionSets.count == 1)
        #expect(payload.manifest.fields.first(where: { $0.key == "picture" })?.type == "image")
        let imagePath = try #require(payload.manifest.rows.first?["picture"])
        #expect(imagePath.hasPrefix("media/"))
        #expect(try Data(contentsOf: payload.root.appendingPathComponent(imagePath)) == imageBytes)
        #expect(payload.manifest.rows.first?["name"] == "Example")
    }
}
