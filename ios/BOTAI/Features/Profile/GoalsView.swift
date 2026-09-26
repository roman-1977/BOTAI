import SwiftUI
struct GoalsView: View {
 @State private var store=GoalsStore(); @State private var title=""; @State private var date=Date().addingTimeInterval(86400*30); @State private var hasDate=true
 var body: some View { List {
                Section("Пример планов MVP") {
                    ForEach(MVPDemoData.plans) { plan in VStack(alignment:.leading) { Text(plan.title).font(.headline); Text(plan.subtitle).font(.caption).foregroundStyle(.secondary); ProgressView(value: plan.progress) } }
                }; Section("Новая цель") { TextField("Например: экзамен по химии",text:$title); Toggle("Есть дата",isOn:$hasDate); if hasDate { DatePicker("Срок",selection:$date,displayedComponents:.date) }; Button("Добавить") { let t=title; title=""; Task { await store.add(title:t,date:hasDate ? date:nil) } }.disabled(title.trimmingCharacters(in:.whitespaces).isEmpty) }; Section("Мои цели") { ForEach(store.goals) { g in VStack(alignment:.leading){Text(g.title).font(.headline); if let d=g.target_date { Text("до \(d)").font(.caption).foregroundStyle(.secondary) } } } } }.navigationTitle("Цели").task{await store.refresh()}.refreshable{await store.refresh()} }
}
