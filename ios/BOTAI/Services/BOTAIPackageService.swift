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
            return .init(manifest: manifest, root: root)
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }
    static func validateArchive(_ url: URL) throws {
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
        guard foundManifest else { throw BOTAIPackageError.invalidManifest }
    }
    static func write(_ c:MaterialContent)throws->URL{let root=FileManager.default.temporaryDirectory.appendingPathComponent("botai-export-\(UUID().uuidString)",isDirectory:true),media=root.appendingPathComponent("media",isDirectory:true);try FileManager.default.createDirectory(at:media,withIntermediateDirectories:true);let exts=Set(["png","jpg","jpeg","webp","heic"]);var rows:[[String:String]]=[],mediaKeys=Set<String>();for r in c.rows{var v=r.values;for(k,value)in r.values{let u=MaterialMediaStore.resolvedURL(for:value) ?? URL(fileURLWithPath:value);if (MaterialMediaStore.isImageReference(value) || exts.contains(u.pathExtension.lowercased())),FileManager.default.fileExists(atPath:u.path){let n="\(UUID().uuidString)-\(u.lastPathComponent)";try FileManager.default.copyItem(at:u,to:media.appendingPathComponent(n));v[k]="media/\(n)";mediaKeys.insert(k)}};rows.append(v)};let fields=c.fields.map{PackageField(key:$0.key,title:$0.title,position:$0.position,type:mediaKeys.contains($0.key) ? "image":"text")};let sets=c.rules.map{PackageQuestionSet(kind:$0.kind,promptTemplate:$0.promptTemplate,promptFieldKeys:$0.promptFieldKeys,answers:$0.answers,showCorrectCount:$0.showCorrectCount,enabled:$0.enabled)};let m=BOTAIPackageManifest(formatVersion:1,title:c.material.title,description:c.material.description,author:c.material.author ?? (c.material.source == .created ? "Вы" : nil),tags:c.material.topic,kind:c.material.kind,fields:fields,rows:rows,questionSets:sets);let e=JSONEncoder();e.outputFormatting=[.prettyPrinted,.sortedKeys,.withoutEscapingSlashes];try e.encode(m).write(to:root.appendingPathComponent("manifest.json"));let out=FileManager.default.temporaryDirectory.appendingPathComponent(c.material.title.replacingOccurrences(of:"/",with:"-")).appendingPathExtension("botai");try? FileManager.default.removeItem(at:out);try FileManager.default.zipItem(at:root,to:out,shouldKeepParent:false);return out}
}
