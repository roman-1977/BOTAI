import Foundation
import CryptoKit

enum QuizQuestionFactory {
    static func questions(quizID: UUID, cards: [(String,String)]) -> [StudyQuestion] {
        cards.enumerated().map { index, card in
            StudyQuestion(id: stableID(quizID: quizID, index: index), prompt: card.0, answer: card.1, kind: .reveal, choices: [], correctChoiceIndexes: [])
        }
    }
    static func stableID(quizID: UUID, index: Int) -> UUID {
        let digest = SHA256.hash(data: Data("\(quizID.uuidString):\(index)".utf8))
        var bytes = Array(digest.prefix(16)); bytes[6] = (bytes[6] & 0x0F) | 0x50; bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
    }
}
