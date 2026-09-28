import Foundation

struct BOTAIPackageManifest: Codable, Equatable, Sendable {
    static let currentFormatVersion = 1
    let formatVersion: Int
    let title: String
    let description: String?
    let tags: String?
    let kind: MaterialKind
    let fields: [PackageField]
    let rows: [[String:String]]
    let questionSets: [PackageQuestionSet]
}
struct PackageField: Codable, Equatable, Sendable { let key:String;let title:String;let position:Int;let type:String }
struct PackageQuestionSet: Codable, Equatable, Sendable { let kind:QuestionRuleKind;let promptTemplate:String;let promptFieldKeys:[String];let answers:[QuestionAnswerRule];let showCorrectCount:Bool;let enabled:Bool }
enum BOTAIPackageError: Error { case unsupportedVersion, invalidManifest, unsafePath }
