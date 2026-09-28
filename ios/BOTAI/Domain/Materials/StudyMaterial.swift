import Foundation

enum MaterialSource: String, Codable, Sendable { case created, importedPackage, library, assigned }
enum MaterialKind: String, Codable, Sendable { case quiz, reference }
enum QuestionRuleKind: String, Codable, Sendable { case card, singleChoice, multipleChoice }

struct StudyMaterialRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var subject: String?
    var topic: String?
    var kind: MaterialKind
    var source: MaterialSource
    var createdAt: Date
    var updatedAt: Date
}

struct MaterialField: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let materialID: UUID
    var key: String
    var title: String
    var position: Int
}

struct KnowledgeRow: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let materialID: UUID
    var position: Int
    var values: [String: String]
}

struct QuestionRule: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let materialID: UUID
    var kind: QuestionRuleKind
    var promptFieldKey: String
    var answerFieldKey: String
    var enabled: Bool
}
