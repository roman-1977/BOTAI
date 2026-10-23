import Foundation
import Testing
@testable import BOTAI

struct CardGenerationTests {
    @Test func missingPromptOrAnswerIsSkippedForEveryMapping() throws {
        let table = try #require(TableImportParser.parse("Название\tФормула\tОстаток\nСерная\tH2SO4\tSO4\nСоляная\tHCl\t\nАзотная\t\tNO3"))
        let maps: Set<CardMapping> = [.init(from: 0, to: 1), .init(from: 1, to: 0), .init(from: 0, to: 2), .init(from: 2, to: 0)]
        let cards = TableImportParser.cards(table: table, mappings: maps)
        #expect(cards.count == 8)
        #expect(cards.allSatisfy { !$0.0.contains(": \n") && !$0.1.isEmpty })
    }

    @Test func malformedAndUnevenDelimitedTablesAreRejected() {
        #expect(TableImportParser.parse("A,B\n\"unclosed,2") == nil)
        #expect(TableImportParser.parse("A,B\n1,2,3") == nil)
        #expect(TableImportParser.parse("A,B\n") == nil)
    }

    @Test func escapedQuotesAndMultilineCells() throws {
        let table = try #require(TableImportParser.parse("Question,Answer\n\"Line 1\nLine \"\"2\"\"\",OK"))
        #expect(table.rows.count == 1)
        #expect(table.rows[0][0] == "Line 1\nLine \"2\"")
    }
}

struct KnowledgeIdentityTests {
    @Test func twoAssessmentModesShareCanonicalKnowledgeIdentity() {
        let materialID = UUID()
        let rowID = UUID()
        let cardID = UUID()
        let choiceID = UUID()
        let material = StudyMaterialRecord(
            id: materialID, title: "Chemistry", subject: "Химия", topic: "Кислоты",
            kind: .quiz, source: .created, createdAt: .now, updatedAt: .now
        )
        let row = KnowledgeRow(id: rowID, materialID: materialID, position: 0,
            values: ["question":"HCl?", "answer":"соляная кислота",
                     "A":"плавиковая", "B":"соляная кислота", "C":"азотная", "D":"серная"])
        let card = QuestionRule(id: cardID, materialID: materialID, kind: .card,
            promptFieldKey: "question", answerFieldKey: "answer",
            promptFieldKeys: ["question"],
            answers: [.init(template:"{1}", fieldKeys:["answer"], correct:true)],
            enabled: true)
        let choice = QuestionRule(id: choiceID, materialID: materialID, kind: .singleChoice,
            promptFieldKey: "question", answerFieldKey: "answer",
            promptFieldKeys: ["question"],
            answers: ["A","B","C","D"].map { letter in
                .init(template:"{1}", fieldKeys:[letter], correct:letter == "B")
            }, enabled: true)
        let content = MaterialContent(material: material, fields: [], rows: [row], rules: [card, choice])
        let first = StudyQuestionBuilder.questions(for: .init(materialID:materialID,ruleID:cardID), content:content)
        let second = StudyQuestionBuilder.questions(for: .init(materialID:materialID,ruleID:choiceID), content:content)
        #expect(first.count == 1)
        #expect(second.count == 1)
        #expect(first.first?.id != second.first?.id)
        #expect(first.first?.knowledgeID == rowID)
        #expect(second.first?.knowledgeID == rowID)
        #expect(second.first?.correctChoiceIndexes.count == 1)
    }

    @Test func generatedChoicesAreStableAcrossRebuilds() {
        let materialID=UUID(),ruleID=UUID()
        let material=StudyMaterialRecord(id:materialID,title:"Acids",subject:"Химия",topic:nil,kind:.quiz,source:.created,createdAt:.now,updatedAt:.now)
        let rows=(0..<6).map { index in KnowledgeRow(id:UUID(),materialID:materialID,position:index,values:["q":"Q\(index)","a":"A\(index)"]) }
        let rule=QuestionRule(id:ruleID,materialID:materialID,kind:.singleChoice,promptFieldKey:"q",answerFieldKey:"a",promptFieldKeys:["q"],answers:[.init(template:"{1}",fieldKeys:["a"],correct:true)],enabled:true)
        let content=MaterialContent(material:material,fields:[],rows:rows,rules:[rule])
        let ref=CourseRuleReference(materialID:materialID,ruleID:ruleID)
        let first=StudyQuestionBuilder.questions(for:ref,content:content)
        let second=StudyQuestionBuilder.questions(for:ref,content:content)
        #expect(first.count == 6)
        #expect(first.map(\.choices) == second.map(\.choices))
        #expect(first.map(\.correctChoiceIndexes) == second.map(\.correctChoiceIndexes))
        #expect(first.allSatisfy { $0.choices.count == 4 && $0.correctChoiceIndexes.count == 1 })
    }

    @Test func legacyQuestionsDefaultKnowledgeIdentityToQuestionID() {
        let id = UUID()
        let q = StudyQuestion(id:id,prompt:"Q",answer:"A",kind:.reveal,choices:[],correctChoiceIndexes:[])
        #expect(q.knowledgeID == id)
    }
}
