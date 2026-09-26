import SwiftUI
struct MyQuizzesView:View { @State private var store=MyQuizzesStore(); @State private var create=false
 var body:some View { Group { if store.quizzes.isEmpty { ContentUnavailableView("Нет своих опросников",systemImage:"square.and.pencil",description:Text("Создай первый материал.")) } else { List(store.quizzes){q in VStack(alignment:.leading){Text("Мой опросник").font(.headline);Text(q.id.uuidString).font(.caption2).foregroundStyle(.secondary);Text(q.created_at,style:.date).font(.caption)} } } }.navigationTitle("Мои опросники").toolbar{Button{create=true}label:{Image(systemName:"plus")}}.sheet(isPresented:$create,onDismiss:{Task{await store.refresh()}}){CreateQuizView()}.task{await store.refresh()}.refreshable{await store.refresh()} }
}
