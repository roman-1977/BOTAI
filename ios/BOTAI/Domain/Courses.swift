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
 let id: UUID; var title: String; var description: String; var subject: String; var audience: String; var estimatedMinutes: Int?; var author: String?; var language: String; var coverSymbol: String; var source: CourseSource; var sections: [CourseSection]; var goals: [LearningGoal]; var createdAt: Date; var updatedAt: Date
 var topicCount:Int { sections.reduce(0){$0+$1.topics.count} }
 var questionSetCount:Int { sections.flatMap(\.topics).reduce(0){$0+$1.questionSets.count} }
}

extension StudyCourse {
 enum CodingKeys:String,CodingKey { case id,title,description,subject,audience,estimatedMinutes,author,language,coverSymbol,source,sections,goals,createdAt,updatedAt }
 init(from decoder:Decoder)throws { let c=try decoder.container(keyedBy:CodingKeys.self);id=try c.decode(UUID.self,forKey:.id);title=try c.decode(String.self,forKey:.title);description=try c.decode(String.self,forKey:.description);subject=try c.decode(String.self,forKey:.subject);audience=try c.decode(String.self,forKey:.audience);estimatedMinutes=try c.decodeIfPresent(Int.self,forKey:.estimatedMinutes);author=try c.decodeIfPresent(String.self,forKey:.author);language=try c.decode(String.self,forKey:.language);coverSymbol=try c.decode(String.self,forKey:.coverSymbol);source=try c.decode(CourseSource.self,forKey:.source);sections=try c.decode([CourseSection].self,forKey:.sections);goals=try c.decodeIfPresent([LearningGoal].self,forKey:.goals) ?? [];createdAt=try c.decode(Date.self,forKey:.createdAt);updatedAt=try c.decode(Date.self,forKey:.updatedAt) }
}
