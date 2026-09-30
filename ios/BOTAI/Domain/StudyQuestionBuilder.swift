import Foundation
import CryptoKit

enum StudyQuestionBuilder {
    static func questions(for ref: CourseRuleReference, content: MaterialContent) -> [StudyQuestion] {
        guard let rule=content.rules.first(where:{$0.id == ref.ruleID}), rule.enabled else { return [] }
        return content.rows.compactMap { row in
            // A row can generate a card only when every field required by the prompt exists.
            // This is a global rule for every material, not material-specific cleanup.
            guard fieldsPresent(rule.promptFieldKeys, in: row) else { return nil }
            let prompt=render(rule.promptTemplate,keys:rule.promptFieldKeys,row:row)
            guard !prompt.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { return nil }
            let rendered=rule.answers.compactMap { answer -> (text:String,correct:Bool)? in
                guard fieldsPresent(answer.fieldKeys, in: row) else { return nil }
                let text=render(answer.template,keys:answer.fieldKeys,row:row).trimmingCharacters(in:.whitespacesAndNewlines)
                return text.isEmpty ? nil : (text,answer.correct)
            }
            let fallback = fieldsPresent([rule.answerFieldKey], in: row) ? render("{1}",keys:[rule.answerFieldKey],row:row).trimmingCharacters(in:.whitespacesAndNewlines) : ""
            let correctTexts=rendered.filter(\.correct).map(\.text)
            guard !correctTexts.isEmpty || !fallback.isEmpty else { return nil }
            var options = rendered
            if rule.kind != .card && options.count < 4 {
                let correctTemplates = rule.answers.filter(\.correct)
                var pool = content.rows.filter { $0.id != row.id }.flatMap { other in
                    correctTemplates.compactMap { a -> String? in
                        guard fieldsPresent(a.fieldKeys, in: other) else { return nil }
                        let text=render(a.template,keys:a.fieldKeys,row:other).trimmingCharacters(in:.whitespacesAndNewlines)
                        return text.isEmpty ? nil:text
                    }
                }.filter { candidate in !options.contains(where:{$0.text == candidate}) }.shuffled()
                while options.count < 4, !pool.isEmpty { let x=pool.removeFirst();if !options.contains(where:{$0.text == x}) { options.append((x,false)) } }
            }
            let shuffled = options.shuffled()
            let answers=shuffled.map(\.text)
            let correct=Set(shuffled.enumerated().compactMap{$0.element.correct ? $0.offset:nil})
            let answer=correctTexts.joined(separator:", ")
            let kind:StudyQuestion.Kind = rule.kind == .singleChoice ? .singleChoice : rule.kind == .multipleChoice ? .multipleChoice : .reveal
            return StudyQuestion(id:stableID(ruleID:rule.id,rowID:row.id),prompt:prompt,answer:answer.isEmpty ? fallback:answer,kind:kind,choices:answers,correctChoiceIndexes:correct)
        }
    }
    private static func fieldsPresent(_ keys:[String],in row:KnowledgeRow)->Bool { keys.allSatisfy { !(row.values[$0] ?? "").trimmingCharacters(in:.whitespacesAndNewlines).isEmpty } }
    static func stableID(ruleID:UUID,rowID:UUID)->UUID { let digest=SHA256.hash(data:Data("\(ruleID.uuidString):\(rowID.uuidString)".utf8));var b=Array(digest.prefix(16));b[6]=(b[6]&0x0F)|0x50;b[8]=(b[8]&0x3F)|0x80;return UUID(uuid:(b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15])) }
    private static func render(_ template:String,keys:[String],row:KnowledgeRow)->String { var x=template;for(i,k) in keys.enumerated(){x=x.replacingOccurrences(of:"{\(i+1)}",with:row.values[k] ?? "—")};return x }
}

struct DailyStudyPlan: Sendable {
    struct GoalPlan: Identifiable, Sendable { let id:UUID;let courseID:UUID;let goalID:UUID;let title:String;let minutes:Int;let questions:[StudyQuestion];let mastery:Int;let target:Int;let deadline:Date? }
    let date:Date;let budgetMinutes:Int;let goals:[GoalPlan]
    var questions:[StudyQuestion]{goals.flatMap(\.questions)}
    var plannedMinutes:Int{goals.reduce(0){$0+$1.minutes}}
}
