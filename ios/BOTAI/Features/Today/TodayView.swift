import SwiftUI

struct TodayView: View {
    @Environment(LearningStore.self) private var store
    @State private var showingLibrary=false
    private let plans=MVPDemoData.plans
    var body:some View { NavigationStack { ScrollView { VStack(alignment:.leading,spacing:18) {
        Text("Твой план").font(.title2.bold())
        if let p=plans.first { primary(p) }
        Text("Сегодня ещё").font(.headline)
        ForEach(plans.dropFirst()) { p in planRow(p) }
        Button("Все мои планы") { showingLibrary=true }.frame(maxWidth:.infinity,alignment:.leading)
        GroupBox("За сегодня") { HStack { metric("\(store.completedToday)","ответов"); Spacer(); metric("\(store.streak)","дней подряд"); Spacer(); metric("44%","главная цель") }.frame(maxWidth:.infinity) }
    }.padding() }.navigationTitle("Сегодня").sheet(isPresented:$showingLibrary){NavigationStack{MyQuizzesView()}} } }
    private func primary(_ p:MVPDemoData.Plan)->some View { GroupBox { VStack(alignment:.leading,spacing:12){ Text(p.title).font(.title3.bold()); Text(p.subtitle).foregroundStyle(.secondary); ProgressView(value:p.progress); HStack{Text("\(Int(p.progress*100))% освоено");Spacer();Text("~\(p.minutes) мин").foregroundStyle(.secondary)}.font(.subheadline); Button("ПРОДОЛЖИТЬ · \(p.today) ВОПРОСОВ") { showingLibrary=true }.buttonStyle(.borderedProminent).controlSize(.large).frame(maxWidth:.infinity); Text("\(p.due) повторить · \(p.fresh) новых").font(.caption).foregroundStyle(.secondary) } } }
    private func planRow(_ p:MVPDemoData.Plan)->some View { GroupBox { VStack(alignment:.leading,spacing:8){ HStack{VStack(alignment:.leading){Text(p.title).font(.headline);Text(p.subtitle).font(.caption).foregroundStyle(.secondary)};Spacer();Text("\(p.today)").font(.title3.bold())}; ProgressView(value:p.progress); HStack{Text("\(Int(p.progress*100))%");Spacer();Text("~\(p.minutes) мин")}.font(.caption).foregroundStyle(.secondary) } } }
    private func metric(_ value:String,_ label:String)->some View { VStack{Text(value).font(.title2.bold());Text(label).font(.caption).foregroundStyle(.secondary)} }
}
