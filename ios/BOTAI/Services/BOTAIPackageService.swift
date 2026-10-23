import Foundation
import ZIPFoundation

struct BOTAIPackagePayload: Identifiable { let id=UUID(); let manifest:BOTAIPackageManifest; let root:URL }
enum BOTAIPackageService {
    static func read(_ url: URL) throws -> BOTAIPackagePayload {
        try validateArchive(url)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("botai-package-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        do {
            try FileManager.default.unzipItem(at: url, to: root)
            let manifestURL = root.appendingPathComponent("manifest.json")
            let data = try Data(contentsOf: manifestURL)
            guard data.count <= 2_000_000 else { throw BOTAIPackageError.invalidManifest }
            let manifest = try JSONDecoder().decode(BOTAIPackageManifest.self, from: data)
            guard manifest.formatVersion == BOTAIPackageManifest.currentFormatVersion else {
                throw BOTAIPackageError.unsupportedVersion
            }
            guard !manifest.title.isEmpty, !manifest.fields.isEmpty,
                  !manifest.rows.isEmpty, !manifest.questionSets.isEmpty else {
                throw BOTAIPackageError.invalidManifest
            }
            try validateManifest(manifest)
            return .init(manifest: manifest, root: root)
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }
    static func validateManifest(_ manifest: BOTAIPackageManifest) throws {
        let keys = manifest.fields.map(\.key)
        guard Set(keys).count == keys.count,
              keys.allSatisfy({ !$0.isEmpty }),
              manifest.rows.allSatisfy({ Set($0.keys).isSubset(of: Set(keys)) }) else {
            throw BOTAIPackageError.invalidManifest
        }
        if let course = manifest.coursePlan {
            guard !course.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,
                  !course.goals.isEmpty,
                  course.goals.allSatisfy({ goal in
                      !goal.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty &&
                      (1...100).contains(goal.masteryTarget) &&
                      !goal.questionSetIndexes.isEmpty &&
                      goal.questionSetIndexes.allSatisfy { $0 >= 0 && $0 < manifest.questionSets.count && manifest.questionSets[$0].enabled }
                  }),
                  course.sections.allSatisfy({ section in
                      !section.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty &&
                      !section.topics.isEmpty &&
                      section.topics.allSatisfy({ topic in
                          !topic.title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty &&
                          !topic.questionSetIndexes.isEmpty &&
                          topic.questionSetIndexes.allSatisfy { $0 >= 0 && $0 < manifest.questionSets.count && manifest.questionSets[$0].enabled }
                      })
                  }) else { throw BOTAIPackageError.invalidManifest }
        }
        for field in manifest.fields where field.type == "image" {
            for row in manifest.rows {
                guard let path = row[field.key], !path.isEmpty else { continue }
                let parts = path.split(separator: "/")
                guard path.hasPrefix("media/"), !path.contains("\\"),
                      !path.contains(":"), !parts.contains(".."), !parts.contains("."),
                      !path.hasPrefix("/") else { throw BOTAIPackageError.unsafePath }
            }
        }
    }
    static func validateArchive(_ url: URL, requiresManifest: Bool = true) throws {
        let archive = try Archive(url: url, accessMode: .read)
        var count = 0
        var expanded: UInt64 = 0
        var foundManifest = false
        for entry in archive {
            count += 1
            guard count <= 1_000 else { throw BOTAIPackageError.invalidManifest }
            let path = entry.path
            let segments = path.split(separator: "/")
            guard !path.hasPrefix("/"), !path.contains("\\"),
                  !segments.contains(".."), !segments.contains("."),
                  !path.contains(":"), entry.type != .symlink else {
                throw BOTAIPackageError.unsafePath
            }
            guard entry.uncompressedSize <= 20_000_000,
                  expanded <= 100_000_000 - entry.uncompressedSize else {
                throw BOTAIPackageError.invalidManifest
            }
            expanded += entry.uncompressedSize
            if path == "manifest.json" { foundManifest = true }
        }
        guard !requiresManifest || foundManifest else { throw BOTAIPackageError.invalidManifest }
    }
    static func write(_ c:MaterialContent)throws->URL{let root=FileManager.default.temporaryDirectory.appendingPathComponent("botai-export-\(UUID().uuidString)",isDirectory:true),media=root.appendingPathComponent("media",isDirectory:true);try FileManager.default.createDirectory(at:media,withIntermediateDirectories:true);let exts=Set(["png","jpg","jpeg","webp","heic"]);var rows:[[String:String]]=[],mediaKeys=Set<String>();for r in c.rows{var v=r.values;for(k,value)in r.values{let u=MaterialMediaStore.resolvedURL(for:value) ?? URL(fileURLWithPath:value);if (MaterialMediaStore.isImageReference(value) || exts.contains(u.pathExtension.lowercased())),FileManager.default.fileExists(atPath:u.path){let n="\(UUID().uuidString)-\(u.lastPathComponent)";try FileManager.default.copyItem(at:u,to:media.appendingPathComponent(n));v[k]="media/\(n)";mediaKeys.insert(k)}};rows.append(v)};let fields=c.fields.map{PackageField(key:$0.key,title:$0.title,position:$0.position,type:mediaKeys.contains($0.key) ? "image":"text")};let sets=c.rules.map{PackageQuestionSet(kind:$0.kind,promptTemplate:$0.promptTemplate,promptFieldKeys:$0.promptFieldKeys,answers:$0.answers,showCorrectCount:$0.showCorrectCount,enabled:$0.enabled)};let m=BOTAIPackageManifest(formatVersion:1,title:c.material.title,description:c.material.description,author:c.material.author ?? (c.material.source == .created ? "Вы" : nil),tags:c.material.topic,kind:c.material.kind,fields:fields,rows:rows,questionSets:sets);let e=JSONEncoder();e.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes];try e.encode(m).write(to:root.appendingPathComponent("manifest.json"));let out=FileManager.default.temporaryDirectory.appendingPathComponent(c.material.title.replacingOccurrences(of:"/",with:"-")).appendingPathExtension("botai");try? FileManager.default.removeItem(at:out);try FileManager.default.zipItem(at:root,to:out,shouldKeepParent:false);return out}
}


/// Imports a learner course as one logical operation. A failed course save
/// rolls back the newly imported material; unrelated library data is untouched.
@MainActor enum LearnerPackageImport {
 static func run(payload:BOTAIPackagePayload,title:String,materials:MaterialStore,courses:CourseStore) throws {
  try BOTAIPackageService.validateManifest(payload.manifest)
  if let plan=payload.manifest.coursePlan {
   let placeholders=payload.manifest.questionSets.map { _ in CourseRuleReference(materialID:UUID(),ruleID:UUID()) }
   _ = try BundledCourseImporter.course(plan:plan,manifest:payload.manifest,references:placeholders)
  }
  let references=try materials.importPackagePayload(payload,title:title)
  guard let plan=payload.manifest.coursePlan else { return }
  do {
   let course=try BundledCourseImporter.course(plan:plan,manifest:payload.manifest,references:references)
   try courses.saveOrThrow(course)
  } catch {
   let importError=error
   // The importer created exactly one material for this manifest.
   if let id=references.first?.materialID {
    do { try materials.delete(id:id) }
    catch { throw NSError(domain:"BOTAI.ImportRollback",code:1,userInfo:[NSLocalizedDescriptionKey:"Course import failed: \(importError.localizedDescription); material rollback failed: \(error.localizedDescription)"]) }
   }
   throw importError
  }
 }
}

/// Builds the persisted learner course from a validated bundled plan and the
/// actual generated rule IDs. Kept outside SwiftUI for deterministic testing.
enum BundledCourseImporter {
 static func course(plan:PackageCoursePlan,manifest:BOTAIPackageManifest,references:[CourseRuleReference],date:Date = .now) throws -> StudyCourse {
  try BOTAIPackageService.validateManifest(manifest)
  guard manifest.coursePlan == plan,references.count == manifest.questionSets.count else { throw BOTAIPackageError.invalidManifest }
  let goals=plan.goals.map { goal in
   LearningGoal(id:UUID(),title:goal.title,questionSets:goal.questionSetIndexes.map { references[$0] },masteryTarget:goal.masteryTarget,deadline:goal.deadline,state:.active,guidance:goal.guidance)
  }
  let sections=plan.sections.map { section in
   CourseSection(id:UUID(),title:section.title,description:"",estimatedMinutes:nil,topics:section.topics.map { topic in
    CourseTopic(id:UUID(),title:topic.title,questionSets:topic.questionSetIndexes.map { references[$0] })
   })
  }
  return StudyCourse(id:UUID(),title:plan.title,description:manifest.description ?? "",subject:plan.subject,audience:"",estimatedMinutes:nil,author:manifest.author,language:"ru",coverSymbol:"graduationcap.fill",source:.importedPackage,sections:sections,goals:goals,createdAt:date,updatedAt:date)
 }
}
