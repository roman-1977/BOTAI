import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            MyQuizzesView()
                .navigationTitle("Мои опросники")
                .toolbar { ToolbarItem(placement:.topBarLeading) { NavigationLink("Общая библиотека") { PublicLibraryView() } } }
        }
    }
}

struct PublicLibraryView: View {
    @State private var store=PublicLibraryStore()
    var body: some View { Group { if store.publications.isEmpty { ContentUnavailableView("Пока пусто",systemImage:"books.vertical",description:Text("Здесь будут опубликованные материалы, которые можно добавить себе.")) } else { List(store.publications) { item in VStack(alignment:.leading){Text(item.title).font(.headline); if let d=item.description{Text(d).foregroundStyle(.secondary)}} } } }.navigationTitle("Общая библиотека").task{await store.refresh()}.refreshable{await store.refresh()} }
}
