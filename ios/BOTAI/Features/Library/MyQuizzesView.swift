import SwiftUI

struct MyQuizzesView: View {
    @State private var store = MyQuizzesStore()
    @State private var create = false

    var body: some View {
        Group {
            if let error = store.errorMessage, store.quizzes.isEmpty {
                ContentUnavailableView("Не удалось загрузить", systemImage: "wifi.exclamationmark", description: Text(error))
            } else if store.quizzes.isEmpty {
                ContentUnavailableView("Нет своих опросников", systemImage: "square.and.pencil", description: Text("Создай первый материал. Он останется личным, пока ты сам не решишь предложить его к публикации."))
            } else {
                List(store.quizzes) { quiz in
                    NavigationLink { PersonalQuizView(quiz: quiz) } label: { VStack(alignment: .leading, spacing: 6) {
                        Text(quiz.title).font(.headline)
                        if let description = quiz.description { Text(description).foregroundStyle(.secondary) }
                        Text("Личный опросник").font(.caption).foregroundStyle(.secondary)
                    } }
                }
            }
        }
        .navigationTitle("Мои опросники")
        .toolbar { Button { create = true } label: { Image(systemName: "plus") } }
        .sheet(isPresented: $create, onDismiss: { Task { await store.refresh() } }) { CreateQuizView() }
        .task { await store.refresh() }
        .refreshable { await store.refresh() }
    }
}
