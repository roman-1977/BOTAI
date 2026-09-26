import SwiftUI
struct ProgressDashboardView: View {
    @Environment(LearningStore.self) private var store
    var body:some View { NavigationStack { ScrollView { VStack(alignment:.leading,spacing:18){
        GroupBox("Эта неделя") { HStack { metric("\(max(store.thisWeek,43))","ответа"); Spacer(); metric("\(max(store.streak,4))","дня подряд"); Spacer(); metric("76%","уверенно") }.frame(maxWidth:.infinity) }
        Text("По планам").font(.headline)
        ForEach(MVPDemoData.plans) { p in GroupBox { VStack(alignment:.leading,spacing:8){HStack{Text(p.title).font(.headline);Spacer();Text("\(Int(p.progress*100))%").bold()};ProgressView(value:p.progress);Text(p.subtitle).font(.caption).foregroundStyle(.secondary)} } }
        GroupBox("Последние занятия") { VStack(alignment:.leading,spacing:10){ history("Кислоты и кислотные остатки","18 ответов · сегодня"); history("Неправильные глаголы","20 ответов · вчера"); history("Кислоты и кислотные остатки","15 ответов · 24 сентября") }.frame(maxWidth:.infinity,alignment:.leading) }
    }.padding() }.navigationTitle("Прогресс") } }
    private func metric(_ v:String,_ l:String)->some View { VStack{Text(v).font(.title2.bold());Text(l).font(.caption).foregroundStyle(.secondary)} }
    private func history(_ a:String,_ b:String)->some View { VStack(alignment:.leading){Text(a);Text(b).font(.caption).foregroundStyle(.secondary)} }
}
