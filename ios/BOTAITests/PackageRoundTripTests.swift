import Foundation
import Testing
@testable import BOTAI

struct PackageRoundTripTests {
    @Test @MainActor func bundledTeacherCourseImportsMaterialAndGuidanceWithMappedQuestionSets() throws {
        let now=Date()
        let advice=CourseLearningGuidance(priority:.critical,rationale:"Экзамен",difficulty:4,recommendedDailyMinutes:25)
        let plan=PackageCoursePlan(title:"ЕГЭ химия",subject:"Химия",goals:[PackageCourseGoal(title:"Кислоты",questionSetIndexes:[0],masteryTarget:90,deadline:now,guidance:advice)])
        let manifest=BOTAIPackageManifest(formatVersion:1,title:"Кислоты",description:"Тест",author:"Преподаватель",tags:"Химия",kind:.reference,
            fields:[PackageField(key:"q",title:"Вопрос",position:0,type:"text"),PackageField(key:"a",title:"Ответ",position:1,type:"text")],
            rows:[["q":"HCl?","a":"Соляная"]],questionSets:[PackageQuestionSet(kind:.card,promptTemplate:"{1}",promptFieldKeys:["q"],answers:[QuestionAnswerRule(template:"{1}",fieldKeys:["a"],correct:true)],showCorrectCount:false,enabled:true)],coursePlan:plan)
        let decoded=try JSONDecoder().decode(BOTAIPackageManifest.self,from:JSONEncoder().encode(manifest))
        #expect(decoded.coursePlan == plan)
        try BOTAIPackageService.validateManifest(decoded)
        let db=try AppDatabase(),repository=MaterialRepository(database:db)
        let store=MaterialStore(repository:repository)
        let root=FileManager.default.temporaryDirectory.appendingPathComponent("botai-guidance-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let refs=try store.importPackagePayload(BOTAIPackagePayload(manifest:decoded,root:root))
        #expect(refs.count == 1)
        let goal=LearningGoal(id:UUID(),title:plan.goals[0].title,questionSets:refs,masteryTarget:90,deadline:now,state:.active,guidance:advice)
        let course=StudyCourse(id:UUID(),title:plan.title,description:"",subject:plan.subject,audience:"",estimatedMinutes:nil,author:nil,language:"ru",coverSymbol:"book",source:.importedPackage,sections:[],goals:[goal],createdAt:now,updatedAt:now)
        let courseRepo=CourseRepository(database:db)
        try courseRepo.save(course)
        let restored=try #require(CourseRepository(database:db).courses().first)
        #expect(restored.goals.first?.guidance == advice)
        #expect(restored.goals.first?.questionSets == refs)
        #expect(store.content(id:refs[0].materialID)?.rules.first?.id == refs[0].ruleID)
    }

    @Test func invalidTeacherGoalReferencesRejectPackage() throws {
        let plan=PackageCoursePlan(title:"Chemistry",subject:"Химия",goals:[PackageCourseGoal(title:"Broken",questionSetIndexes:[99],masteryTarget:90,deadline:nil,guidance:nil)])
        let manifest=BOTAIPackageManifest(formatVersion:1,title:"Material",description:nil,author:nil,tags:nil,kind:.reference,
            fields:[PackageField(key:"q",title:"Question",position:0,type:"text")],rows:[["q":"HCl"]],
            questionSets:[PackageQuestionSet(kind:.card,promptTemplate:"{1}",promptFieldKeys:["q"],answers:[],showCorrectCount:false,enabled:true)],coursePlan:plan)
        #expect(throws:BOTAIPackageError.self) { try BOTAIPackageService.validateManifest(manifest) }
    }

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

    @Test @MainActor func importedMediaPersistsAndDuplicateReferencesReuseFile() throws {
        let fm = FileManager.default
        let db = try AppDatabase()
        let repo = MaterialRepository(database: db)
        let store = MaterialStore(repository: repo)
        let sourceID = UUID()
        let mediaDir = MaterialMediaStore.directory(for: sourceID)
        try fm.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: mediaDir) }
        let bytes = Data([1, 2, 3, 4, 5, 6])
        try bytes.write(to: mediaDir.appendingPathComponent("shared.png"))
        let now = Date()
        let material = StudyMaterialRecord(id: sourceID, title: "Shared media", subject: nil, topic: nil, kind: .reference, source: .created, createdAt: now, updatedAt: now)
        let fields = [
            MaterialField(id: UUID(), materialID: sourceID, key: "name", title: "Name", position: 0),
            MaterialField(id: UUID(), materialID: sourceID, key: "image", title: "Image", position: 1)
        ]
        let ref = MaterialMediaStore.reference(materialID: sourceID, fileName: "shared.png")
        let rows = (0..<2).map { KnowledgeRow(id: UUID(), materialID: sourceID, position: $0, values: ["name": "Row \($0)", "image": ref]) }
        let rules = [QuestionRule(id: UUID(), materialID: sourceID, kind: .card, promptFieldKey: "name", answerFieldKey: "image", enabled: true)]
        let exported = try BOTAIPackageService.write(MaterialContent(material: material, fields: fields, rows: rows, rules: rules))
        defer { try? fm.removeItem(at: exported) }
        try store.importPackage(exported)
        let imported = try #require(store.materials.first(where: { $0.title == "Shared media" }))
        defer { try? repo.delete(id: imported.id); try? fm.removeItem(at: MaterialMediaStore.directory(for: imported.id)) }
        let content = try #require(store.content(id: imported.id))
        #expect(content.rows.count == 2)
        let first = try #require(content.rows.first?.values["image"])
        let second = try #require(content.rows.last?.values["image"])
        let resolved = try #require(MaterialMediaStore.url(for: first))
        let secondURL = try #require(MaterialMediaStore.url(for: second))
        #expect(try Data(contentsOf: resolved) == bytes)
        #expect(try Data(contentsOf: secondURL) == bytes)
    }

    @Test @MainActor func missingImageRejectsImportAndCleansTemporaryDirectory() throws {
        let fm = FileManager.default
        let db = try AppDatabase()
        let repo = MaterialRepository(database: db)
        let store = MaterialStore(repository: repo)
        let root = fm.temporaryDirectory.appendingPathComponent("botai-broken-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let json = #"""
        {"formatVersion":1,"title":"Broken image fixture","kind":"reference","fields":[{"key":"picture","title":"Picture","position":0,"type":"image"}],"rows":[{"picture":"media/missing.png"}],"questionSets":[{"kind":"card","promptTemplate":"{1}","promptFieldKeys":["picture"],"answers":[{"template":"{1}","fieldKeys":["picture"],"correct":true}],"showCorrectCount":false,"enabled":true}]}
        """#
        let manifest = try JSONDecoder().decode(BOTAIPackageManifest.self, from: Data(json.utf8))
        let before = try repo.materials().count
        do {
            try store.importPackagePayload(BOTAIPackagePayload(manifest: manifest, root: root))
            Issue.record("Expected missing image to reject import")
        } catch {
            #expect(error is BOTAIPackageError)
        }
        #expect(try repo.materials().count == before)
        #expect(!fm.fileExists(atPath: root.path))
    }
}
