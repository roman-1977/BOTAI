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
