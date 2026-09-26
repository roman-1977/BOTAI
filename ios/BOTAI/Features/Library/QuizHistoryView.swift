import SwiftUI
struct QuizHistoryView: View {
    let questions:[StudyQuestion]
    @Environment(LearningStore.self) private var learning
    private var map:[UUID:StudyQuestion] { Dictionary(uniqueKeysWithValues:questions.map{($0.id,$0)}) }
    private var history:[Attempt] { learning.attempts(for:Set(questions.map(\.id))).sorted{$0.occurredAt > $1.occurredAt} }
    var body:some View { List { if history.isEmpty { ContentUnavailableView("Истории пока нет",systemImage:"clock",description:Text("Пройди опрос хотя бы один раз.")) } else { ForEach(history) { a in VStack(alignment:.leading,spacing:4){Text(map[a.questionID]?.prompt ?? "Вопрос").font(.headline); HStack{Text(a.rating.title);Spacer();Text(a.occurredAt,format:.dateTime.day().month().hour().minute()).foregroundStyle(.secondary)}} } } }.navigationTitle("История") }
}
