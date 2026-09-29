import Foundation

enum CourseSource: String, Codable, Sendable { case created, importedPackage, library, assigned }
struct CourseRuleReference: Codable, Hashable, Sendable { let materialID: UUID; let ruleID: UUID }
struct CourseTopic: Identifiable, Codable, Equatable, Sendable { let id: UUID; var title: String; var questionSets: [CourseRuleReference] }
struct CourseSection: Identifiable, Codable, Equatable, Sendable { let id: UUID; var title: String; var description: String; var estimatedMinutes: Int?; var topics: [CourseTopic] }
enum LearningGoalState: String, Codable, Sendable { case planned, active, paused, completed }
struct LearningGoal: Identifiable, Codable, Equatable, Sendable {
 let id: UUID; var title: String; var questionSets: [CourseRuleReference]; var masteryTarget: Int; var deadline: Date?; var state: LearningGoalState
}
struct StudyCourse: Identifiable, Codable, Equatable, Sendable {
 let id: UUID; var title: String; var description: String; var subject: String; var audience: String; var estimatedMinutes: Int?; var author: String?; var language: String; var coverSymbol: String; var source: CourseSource; var sections: [CourseSection]; var goals: [LearningGoal] = []; var createdAt: Date; var updatedAt: Date
 var topicCount:Int { sections.reduce(0){$0+$1.topics.count} }
 var questionSetCount:Int { sections.flatMap(\.topics).reduce(0){$0+$1.questionSets.count} }
}
