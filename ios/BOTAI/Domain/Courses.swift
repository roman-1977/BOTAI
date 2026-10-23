import Foundation

enum CourseSource: String, Codable, Sendable { case created, importedPackage, library, assigned }
struct CourseRuleReference: Codable, Hashable, Sendable { let materialID: UUID; let ruleID: UUID }
struct CourseTopic: Identifiable, Codable, Equatable, Sendable { let id: UUID; var title: String; var questionSets: [CourseRuleReference] }
struct CourseSection: Identifiable, Codable, Equatable, Sendable { let id: UUID; var title: String; var description: String; var estimatedMinutes: Int?; var topics: [CourseTopic] }
enum LearningGoalState: String, Codable, Sendable { case planned, active, paused, completed }
/// Optional guidance imported with a course or provided by a trusted local seed.
/// Existing courses without guidance remain compatible.
struct CourseLearningGuidance: Codable, Equatable, Sendable {
 enum Priority: String, Codable, Sendable { case standard, elevated, critical }
 var priority: Priority
 var rationale: String?
 /// Teacher-provided expected complexity (1 = introductory, 5 = advanced).
 var difficulty: Int? = nil
 /// Suggested study minutes, never applied as a silent profile-budget override.
 var recommendedDailyMinutes: Int? = nil
 enum CodingKeys: String, CodingKey { case priority, rationale, difficulty, recommendedDailyMinutes }
 init(priority: Priority, rationale: String? = nil, difficulty: Int? = nil, recommendedDailyMinutes: Int? = nil) {
  self.priority=priority;self.rationale=rationale
  self.difficulty=difficulty.flatMap { (1...5).contains($0) ? $0 : nil }
  self.recommendedDailyMinutes=recommendedDailyMinutes.flatMap { (1...240).contains($0) ? $0 : nil }
 }
 init(from decoder: Decoder) throws {
  let c=try decoder.container(keyedBy:CodingKeys.self)
  priority=try c.decode(Priority.self,forKey:.priority)
  rationale=try c.decodeIfPresent(String.self,forKey:.rationale)
  let d=try c.decodeIfPresent(Int.self,forKey:.difficulty)
  difficulty=d.flatMap { (1...5).contains($0) ? $0 : nil }
  let m=try c.decodeIfPresent(Int.self,forKey:.recommendedDailyMinutes)
  recommendedDailyMinutes=m.flatMap { (1...240).contains($0) ? $0 : nil }
 }
}
extension CourseLearningGuidance.Priority {
 var studentLabel: String {
  switch self { case .standard: return "Обычный"; case .elevated: return "Повышенный"; case .critical: return "Высокий" }
 }
}
struct LearningGoal: Identifiable, Codable, Equatable, Sendable {
 let id: UUID; var title: String; var questionSets: [CourseRuleReference]; var masteryTarget: Int; var deadline: Date?; var state: LearningGoalState
 var guidance: CourseLearningGuidance? = nil
 enum CodingKeys: String, CodingKey { case id,title,questionSets,masteryTarget,deadline,state,guidance }
 init(id: UUID, title: String, questionSets: [CourseRuleReference], masteryTarget: Int, deadline: Date?, state: LearningGoalState, guidance: CourseLearningGuidance? = nil) {
  self.id=id;self.title=title;self.questionSets=questionSets;self.masteryTarget=masteryTarget;self.deadline=deadline;self.state=state;self.guidance=guidance
 }
 init(from decoder: Decoder) throws {
  let c=try decoder.container(keyedBy:CodingKeys.self)
  id=try c.decode(UUID.self,forKey:.id);title=try c.decode(String.self,forKey:.title)
  questionSets=try c.decode([CourseRuleReference].self,forKey:.questionSets)
  masteryTarget=try c.decode(Int.self,forKey:.masteryTarget)
  deadline=try c.decodeIfPresent(Date.self,forKey:.deadline)
  state=try c.decode(LearningGoalState.self,forKey:.state)
  guidance=try c.decodeIfPresent(CourseLearningGuidance.self,forKey:.guidance)
 }
}
struct StudyCourse: Identifiable, Codable, Equatable, Sendable {
 let id: UUID; var title: String; var description: String; var subject: String; var audience: String; var estimatedMinutes: Int?; var author: String?; var language: String; var coverSymbol: String; var source: CourseSource; var sections: [CourseSection]; var goals: [LearningGoal]; var createdAt: Date; var updatedAt: Date
 /// Explicit section sequence for staged learning; absent for legacy courses.
 var stagedLearning: StagedLearningRoute? = nil
 var topicCount:Int { sections.reduce(0){$0+$1.topics.count} }
 var questionSetCount:Int { sections.flatMap(\.topics).reduce(0){$0+$1.questionSets.count} }
}

struct StagedLearningRoute: Codable, Equatable, Sendable {
 var sectionIDs: [UUID]
 var threshold: Int
}

extension StudyCourse {
 enum CodingKeys:String,CodingKey { case id,title,description,subject,audience,estimatedMinutes,author,language,coverSymbol,source,sections,goals,createdAt,updatedAt,stagedLearning }
 init(from decoder:Decoder)throws { let c=try decoder.container(keyedBy:CodingKeys.self);id=try c.decode(UUID.self,forKey:.id);title=try c.decode(String.self,forKey:.title);description=try c.decode(String.self,forKey:.description);subject=try c.decode(String.self,forKey:.subject);audience=try c.decode(String.self,forKey:.audience);estimatedMinutes=try c.decodeIfPresent(Int.self,forKey:.estimatedMinutes);author=try c.decodeIfPresent(String.self,forKey:.author);language=try c.decode(String.self,forKey:.language);coverSymbol=try c.decode(String.self,forKey:.coverSymbol);source=try c.decode(CourseSource.self,forKey:.source);sections=try c.decode([CourseSection].self,forKey:.sections);goals=try c.decodeIfPresent([LearningGoal].self,forKey:.goals) ?? [];createdAt=try c.decode(Date.self,forKey:.createdAt);updatedAt=try c.decode(Date.self,forKey:.updatedAt);stagedLearning=try c.decodeIfPresent(StagedLearningRoute.self,forKey:.stagedLearning) }
}

/// Stable local attribution, independent of displayed titles and question text.
/// Ambiguous references are intentionally unattributed rather than guessed.
struct StudyQuestionAttribution: Codable, Equatable, Hashable, Sendable {
    let courseID: UUID
    let sectionID: UUID
    let topicID: UUID
}

enum StudyQuestionAttributionResolver {
    /// A reference may appear in multiple topics/courses; such questions are not assigned
    /// to a single topic unless the session launcher provides explicit scope.
    /// An explicitly selected topic is authoritative even when its question set is
    /// also referenced elsewhere. Mixed/subject launches still use uniqueAttributions.
    static func selectedTopicAttributions(
        courseID: UUID, sectionID: UUID, topic: CourseTopic, questions: [StudyQuestion]
    ) -> [UUID: StudyQuestionAttribution] {
        let attribution = StudyQuestionAttribution(
            courseID: courseID, sectionID: sectionID, topicID: topic.id)
        return Dictionary(uniqueKeysWithValues: Set(questions.map(\.id)).map { ($0, attribution) })
    }

    static func uniqueAttributions(
        courses: [StudyCourse], questionsByReference: [CourseRuleReference: [StudyQuestion]]
    ) -> [UUID: StudyQuestionAttribution] {
        var candidates: [UUID: Set<StudyQuestionAttribution>] = [:]
        for course in courses {
            for section in course.sections {
                for topic in section.topics {
                    let attribution = StudyQuestionAttribution(
                        courseID: course.id, sectionID: section.id, topicID: topic.id)
                    for ref in topic.questionSets {
                        for question in questionsByReference[ref] ?? [] {
                            candidates[question.id, default: []].insert(attribution)
                        }
                    }
                }
            }
        }
        return candidates.compactMapValues { $0.count == 1 ? $0.first : nil }
    }
}

/// One aggregate bucket for a completed session. No answer or question identifier is transmitted.
struct SessionTopicAggregate: Codable, Equatable, Sendable {
    let attribution: StudyQuestionAttribution
    var answered: Int
    var correct: Int
}

/// Local answer-time accumulator. Attribution is captured when the answer is recorded;
/// later course edits must not silently reclassify historical attempts.
struct SessionTopicAccumulator: Codable, Equatable, Sendable {
    private(set) var buckets: [StudyQuestionAttribution: SessionTopicAggregate] = [:]
    private(set) var unattributedAnswered = 0
    private(set) var unattributedCorrect = 0

    mutating func record(correct: Bool, attribution: StudyQuestionAttribution?) {
        guard let attribution else {
            unattributedAnswered += 1
            if correct { unattributedCorrect += 1 }
            return
        }
        var bucket = buckets[attribution] ?? SessionTopicAggregate(
            attribution: attribution, answered: 0, correct: 0)
        bucket.answered += 1
        if correct { bucket.correct += 1 }
        buckets[attribution] = bucket
    }

    var answered: Int { buckets.values.reduce(unattributedAnswered) { $0 + $1.answered } }
    var correct: Int { buckets.values.reduce(unattributedCorrect) { $0 + $1.correct } }
    var breakdown: [SessionTopicAggregate] {
        buckets.values.sorted {
            ($0.attribution.courseID.uuidString, $0.attribution.sectionID.uuidString,
             $0.attribution.topicID.uuidString) <
            ($1.attribution.courseID.uuidString, $1.attribution.sectionID.uuidString,
             $1.attribution.topicID.uuidString)
        }
    }
}
