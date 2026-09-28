import Foundation

struct BOTAIPackageManifest: Codable, Equatable, Sendable {
    static let currentFormatVersion = 1
    let formatVersion: Int
    let title: String
    let subject: String?
    let topic: String?
    let kind: MaterialKind
    let dataFile: String
    let rules: [PackageRule]
}

struct PackageRule: Codable, Equatable, Sendable {
    let kind: QuestionRuleKind
    let from: String
    let to: String
}

enum BOTAIPackageError: Error { case unsupportedVersion, missingDataFile, unsafePath }
