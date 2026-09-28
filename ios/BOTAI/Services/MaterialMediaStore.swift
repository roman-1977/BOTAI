import Foundation

enum MaterialMediaStore {
    static let prefix = "media://"
    static func root() -> URL { FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask).first!.appendingPathComponent("BOTAI/Media",isDirectory:true) }
    static func directory(for materialID:UUID)->URL { root().appendingPathComponent(materialID.uuidString,isDirectory:true) }
    static func reference(materialID:UUID,fileName:String)->String { "\(prefix)\(materialID.uuidString)/\(fileName)" }
    static func url(for value:String)->URL? { guard value.hasPrefix(prefix) else{return nil};let rel=String(value.dropFirst(prefix.count));guard !rel.contains("..") else{return nil};return root().appendingPathComponent(rel) }
    static func resolvedURL(for value:String)->URL? { if let u=url(for:value),FileManager.default.fileExists(atPath:u.path){return u};let old=URL(fileURLWithPath:value);if FileManager.default.fileExists(atPath:old.path){return old};let name=old.lastPathComponent;return (FileManager.default.enumerator(at:root(),includingPropertiesForKeys:nil)?.allObjects as? [URL])?.first{$0.lastPathComponent==name} }
    static func isImageReference(_ value:String)->Bool { if value.hasPrefix(prefix){return true};return ["png","jpg","jpeg","webp","heic"].contains(URL(fileURLWithPath:value).pathExtension.lowercased()) }
}
