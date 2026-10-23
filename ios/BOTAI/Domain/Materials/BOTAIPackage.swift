import Foundation

struct BOTAIPackageManifest: Codable, Equatable, Sendable {
    static let currentFormatVersion = 1
    let formatVersion: Int
    let title: String
    let description: String?
    let author: String?
    let tags: String?
    let kind: MaterialKind
    let fields: [PackageField]
    let rows: [[String:String]]
    let questionSets: [PackageQuestionSet]
    /// Optional learner course bundled with this material. Legacy material-only packages remain valid.
    var coursePlan: PackageCoursePlan? = nil
    enum CodingKeys: String, CodingKey { case formatVersion,title,description,author,tags,kind,fields,rows,questionSets,coursePlan }
    init(formatVersion:Int,title:String,description:String?,author:String?,tags:String?,kind:MaterialKind,fields:[PackageField],rows:[[String:String]],questionSets:[PackageQuestionSet],coursePlan:PackageCoursePlan? = nil) {
     self.formatVersion=formatVersion;self.title=title;self.description=description;self.author=author;self.tags=tags;self.kind=kind;self.fields=fields;self.rows=rows;self.questionSets=questionSets;self.coursePlan=coursePlan
    }
    init(from decoder:Decoder)throws {
     let c=try decoder.container(keyedBy:CodingKeys.self)
     formatVersion=try c.decode(Int.self,forKey:.formatVersion);title=try c.decode(String.self,forKey:.title)
     description=try c.decodeIfPresent(String.self,forKey:.description);author=try c.decodeIfPresent(String.self,forKey:.author)
     tags=try c.decodeIfPresent(String.self,forKey:.tags);kind=try c.decode(MaterialKind.self,forKey:.kind)
     fields=try c.decode([PackageField].self,forKey:.fields);rows=try c.decode([[String:String]].self,forKey:.rows)
     questionSets=try c.decode([PackageQuestionSet].self,forKey:.questionSets)
     coursePlan=try c.decodeIfPresent(PackageCoursePlan.self,forKey:.coursePlan)
    }
}
struct PackageCoursePlan: Codable, Equatable, Sendable {
 let title:String
 let subject:String
 let goals:[PackageCourseGoal]
 var sections:[PackageCourseSection] = []
 enum CodingKeys:String,CodingKey { case title,subject,goals,sections }
 init(title:String,subject:String,goals:[PackageCourseGoal],sections:[PackageCourseSection] = []) {
  self.title=title;self.subject=subject;self.goals=goals;self.sections=sections
 }
 init(from decoder:Decoder)throws {
  let c=try decoder.container(keyedBy:CodingKeys.self)
  title=try c.decode(String.self,forKey:.title);subject=try c.decode(String.self,forKey:.subject)
  goals=try c.decode([PackageCourseGoal].self,forKey:.goals)
  sections=try c.decodeIfPresent([PackageCourseSection].self,forKey:.sections) ?? []
 }
}
struct PackageCourseSection:Codable,Equatable,Sendable {
 let title:String
 let topics:[PackageCourseTopic]
}
struct PackageCourseTopic:Codable,Equatable,Sendable {
 let title:String
 let questionSetIndexes:[Int]
}
struct PackageCourseGoal: Codable, Equatable, Sendable {
 let title:String
 let questionSetIndexes:[Int]
 let masteryTarget:Int
 let deadline:Date?
 let guidance:CourseLearningGuidance?
}
struct PackageField: Codable, Equatable, Sendable { let key:String;let title:String;let position:Int;let type:String }
struct PackageQuestionSet: Codable, Equatable, Sendable { let kind:QuestionRuleKind;let promptTemplate:String;let promptFieldKeys:[String];let answers:[QuestionAnswerRule];let showCorrectCount:Bool;let enabled:Bool }
enum BOTAIPackageError: Error { case unsupportedVersion, invalidManifest, unsafePath }
