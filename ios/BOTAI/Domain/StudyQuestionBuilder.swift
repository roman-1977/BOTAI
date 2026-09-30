import Foundation
import CryptoKit

enum StudyQuestionBuilder {
    static func questions(for ref: CourseRuleReference, content: MaterialContent) -> [StudyQuestion] {
        guard let rule=content.rules.first(where:{$0.id == ref.ruleID}), rule.enabled else { return [] }
        return content.rows.map { row in
            let prompt=render(rule.promptTemplate,keys:rule.promptFieldKeys,row:row)
            let rendered=rule.answers.map{(text:render($0.template,keys:$0.fieldKeys,row:row),correct:$0.correct)}.filter{!$0.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty}
            let answers=rendered.map(\.text)
            let correct=Set(rendered.enumerated().compactMap{$0.element.correct ? $0.offset:nil})
            let answer=rendered.filter(\.correct).map(\.text).joined(separator:", ")
            let kind:StudyQuestion.Kind = rule.kind == .singleChoice ? .singleChoice : rule.kind == .multipleChoice ? .multipleChoice : .reveal
            let fallback=render("{1}",keys:[rule.answerFieldKey],row:row)
            return StudyQuestion(id:stableID(ruleID:rule.id,rowID:row.id),prompt:prompt,answer:answer.isEmpty ? fallback:answer,kind:kind,choices:answers,correctChoiceIndexes:correct)
        }
    }
    static func stableID(ruleID:UUID,rowID:UUID)->UUID { let digest=SHA256.hash(data:Data("\(ruleID.uuidString):\(rowID.uuidString)".utf8));var b=Array(digest.prefix(16));b[6]=(b[6]&0x0F)|0x50;b[8]=(b[8]&0x3F)|0x80;return UUID(uuid:(b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15])) }
    private static func render(_ template:String,keys:[String],row:KnowledgeRow)->String { var x=template;for(i,k) in keys.enumerated(){x=x.replacingOccurrences(of:"{\(i+1)}",with:row.values[k] ?? "—")};return x }
}

struct DailyStudyPlan: Sendable {
    struct GoalPlan: Identifiable, Sendable { let id:UUID;let courseID:UUID;let goalID:UUID;let title:String;let minutes:Int;let questions:[StudyQuestion];let mastery:Int;let target:Int;let deadline:Date? }
    let date:Date;let budgetMinutes:Int;let goals:[GoalPlan]
    var questions:[StudyQuestion]{goals.flatMap(\.questions)}
    var plannedMinutes:Int{goals.reduce(0){$0+$1.minutes}}
}
