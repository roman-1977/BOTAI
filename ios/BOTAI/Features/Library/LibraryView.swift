import SwiftUI

struct LibraryView: View {
    @State private var store = PublicLibraryStore()
    @State private var showingCreate = false
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.publications.isEmpty { ProgressView("Загружаем библиотеку…") }
                else if let error = store.errorMessage, store.publications.isEmpty { ContentUnavailableView("Не удалось загрузить", systemImage: "wifi.exclamationmark", description: Text(error)) }
                else if store.publications.isEmpty { ContentUnavailableView("Пока пусто", systemImage: "books.vertical", description: Text("После модерации здесь появятся опубликованные опросники.")) }
                else { List(store.publications) { item in VStack(alignment: .leading) { Text("Опросник").font(.headline); Text(item.quiz_id.uuidString).font(.caption).foregroundStyle(.secondary); Text(item.published_at, style: .date).font(.caption2) } } }
            }
            .navigationTitle("Библиотека")
            .toolbar { Button { showingCreate = true } label: { Image(systemName: "plus") } }
            .sheet(isPresented: $showingCreate) { CreateQuizView() }
            .refreshable { await store.refresh() }
            .task { await store.refresh() }
        }
    }
}
