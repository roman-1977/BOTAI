import SwiftUI
struct GoalPickerForQuiz: View {
    let quizID:UUID; @State private var store=GoalsStore(); @Environment(\.dismiss) private var dismiss
    var body:some View { NavigationStack { List { if store.goals.isEmpty { ContentUnavailableView("Нет целей",systemImage:"target",description:Text("Создай цель в Профиль → Цели.")) } else { ForEach(store.goals) { goal in Button { Task { await store.attach(goalID:goal.id,quizID:quizID); dismiss() } } label: { VStack(alignment:.leading){Text(goal.title); if let d=goal.target_date{Text("до \(d)").font(.caption).foregroundStyle(.secondary)}} } } } }.navigationTitle("Добавить к цели").toolbar{Button("Закрыть"){dismiss()}}.task{await store.refresh()} } }
}
