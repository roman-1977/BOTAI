import Testing
@testable import BOTAI

struct TableImportParserTests {
    @Test func parsesTSVAndGeneratesDirections() throws {
        let source = "Формула\tНазвание\tОстаток\nH₂SO₄\tСерная\tSO₄²⁻\nHCl\tСоляная\tCl⁻"
        let table = try #require(TableImportParser.parse(source))
        #expect(table.headers.count == 3)
        #expect(table.rows.count == 2)
        let maps: Set<CardMapping> = [.init(from:0,to:1), .init(from:1,to:0), .init(from:0,to:2)]
        let cards = TableImportParser.cards(table: table, mappings: maps)
        #expect(cards.count == 6)
        #expect(cards.contains { $0.0.contains("H₂SO₄") && $0.0.contains("Остаток?") && $0.1 == "SO₄²⁻" })
    }
}

@Test func parsesQuotedCSVWithCommas() throws {
    let source = "Вопрос,Ответ\n\"В коробке 20 шаров, из них 5 белых. Какова вероятность?\",0.25\n"
    let table = try #require(TableImportParser.parse(source))
    #expect(table.rows.count == 1)
    #expect(table.rows[0][0].contains("20 шаров, из них 5"))
    #expect(table.rows[0][1] == "0.25")
}
