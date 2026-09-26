import SwiftUI
struct QuizProgressView: View {
    let questions:[StudyQuestion]
    @Environment(LearningStore.self) private var learning
    var body:some View { let s=learning.stats(for:questions); List { Section("Освоение") { ProgressView(value:s.coverage); LabeledContent("Изучено",value:"\(s.learned) из \(s.total)"); LabeledContent("Ответов всего",value:"\(s.attempts)"); LabeledContent("Сегодня",value:"\(s.today)") }; Section("Самооценка ответов") { LabeledContent("Знаю",value:"\(s.known)"); LabeledContent("С трудом",value:"\(s.hard)"); LabeledContent("Не знаю",value:"\(s.again)"); if s.attempts > 0 { LabeledContent("Доля «Знаю»",value:s.knownRate.formatted(.percent.precision(.fractionLength(0)))) } } }.navigationTitle("Прогресс опросника") }
}
