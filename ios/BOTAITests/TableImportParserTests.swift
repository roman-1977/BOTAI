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
        #expect(cards.contains { $0.0 == "H₂SO₄" && $0.1 == "SO₄²⁻" })
    }
}
