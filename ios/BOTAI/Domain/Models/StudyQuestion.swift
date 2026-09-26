import Foundation
struct StudyQuestion: Identifiable, Sendable, Equatable {
 enum Kind: Sendable { case reveal, singleChoice, multipleChoice }
 let id: UUID; let prompt: String; let answer: String; let kind: Kind; let choices: [String]; let correctChoiceIndexes: Set<Int>
}
