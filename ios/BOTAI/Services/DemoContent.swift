import Foundation
enum DemoContent { static let questions: [StudyQuestion] = [
 .init(id: UUID(), prompt: "Формула площади круга?", answer: "S = πr²", kind: .reveal, choices: [], correctChoiceIndexes: []),
 .init(id: UUID(), prompt: "H₂SO₄", answer: "Серная кислота", kind: .reveal, choices: [], correctChoiceIndexes: []),
 .init(id: UUID(), prompt: "Столица Нидерландов?", answer: "Амстердам", kind: .singleChoice, choices: ["Роттердам", "Амстердам", "Гаага"], correctChoiceIndexes: [1]),
 .init(id: UUID(), prompt: "Какие числа простые?", answer: "2 и 5", kind: .multipleChoice, choices: ["2", "4", "5", "9"], correctChoiceIndexes: [0,2]),
 .init(id: UUID(), prompt: "Ускорение свободного падения?", answer: "≈ 9,8 м/с²", kind: .reveal, choices: [], correctChoiceIndexes: []) ] }
