import Foundation
struct StudyQuestion: Identifiable, Sendable, Equatable {
 enum Kind: Sendable { case reveal, pair, singleChoice, multipleChoice }
 let id: UUID; let prompt: String; let answer: String; let kind: Kind; let choices: [String]; let correctChoiceIndexes: Set<Int>
 let promptLaTeX: String?; let answerLaTeX: String?; let mediaURL: URL?
 init(id:UUID,prompt:String,answer:String,kind:Kind,choices:[String],correctChoiceIndexes:Set<Int>,promptLaTeX:String?=nil,answerLaTeX:String?=nil,mediaURL:URL?=nil){self.id=id;self.prompt=prompt;self.answer=answer;self.kind=kind;self.choices=choices;self.correctChoiceIndexes=correctChoiceIndexes;self.promptLaTeX=promptLaTeX;self.answerLaTeX=answerLaTeX;self.mediaURL=mediaURL}
}
