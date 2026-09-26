import SwiftUI
struct PlansView:View { @Environment(LearningStore.self) private var store; @State private var selected:MVPDemoData.Plan?
 var body:some View { List(MVPDemoData.plans){p in Button{selected=p;store.use(questions:MVPDemoData.questions(for:p))}label:{VStack(alignment:.leading,spacing:6){HStack{Text(p.title).font(.headline);Spacer();Text("\(Int(p.progress*100))%").bold()};Text(p.subtitle).font(.caption).foregroundStyle(.secondary);ProgressView(value:p.progress);Text("Сегодня: \(p.today) · ~\(p.minutes) мин").font(.caption)}}}.navigationTitle("Мои планы").sheet(item:$selected){_ in LearnSessionView()} }
}
