import SwiftUI

struct MaterialsHubView: View {
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var scope = 0
    @State private var filter = "Все"
    @State private var addMaterial = false
    @State private var selectedMaterial: DemoMaterial?
    @State private var selectedRecord: StudyMaterialRecord?

    private let demo = DemoLibraryData()

    var body: some View {
        NavigationStack {
            ZStack {
                DigitalHubBackground()
                ScrollView { VStack(spacing: 18) { scopePicker; if scope == 0 { personal } else { groups } }.padding(16) }
            }
            .navigationTitle("Материалы").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Закрыть") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button { addMaterial = true } label: { Image(systemName: "plus.circle.fill").font(.title2) } }
            }
            .sheet(isPresented: $addMaterial) { AddMaterialSourceView() }
            .sheet(item: $selectedMaterial) { MaterialDetailView(material: $0) }
            .sheet(item: $selectedRecord) { SavedMaterialDetailView(material: $0) }

        }
    }

    private var scopePicker: some View {
        Picker("Библиотека", selection: $scope) { Text("ЛИЧНЫЕ").tag(0); Text("ГРУППОВЫЕ").tag(1) }
            .pickerStyle(.segmented)
    }

    private var personal: some View {
        VStack(spacing: 18) {
            HStack { Label("Курсы", systemImage: "square.stack.3d.up.fill").font(.headline); Spacer(); Button("Создать") {} }.foregroundStyle(.white)
            ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(demo.courses) { courseCard($0) } } }
            HStack { Text("ВСЕ МАТЕРИАЛЫ").font(.caption.bold()).foregroundStyle(.cyan); Spacer(); Text("\(demo.materials.count + store.materials.count)").foregroundStyle(.white.opacity(0.55)) }
            filterBar
            ForEach(filteredDemo) { materialCard($0) }
            ForEach(store.materials) { recordCard($0) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(["Все","Созданные","Импорт","Библиотека"], id: \.self) { item in Button(item) { filter=item }.buttonStyle(HubChip(selected: filter == item)) } } }
    }

    private var filteredDemo: [DemoMaterial] {
        demo.materials.filter { filter == "Все" || (filter == "Созданные" && $0.source == "Мой") || (filter == "Импорт" && $0.source == "Файл") || (filter == "Библиотека" && $0.source == "Библиотека") }
    }

    private func courseCard(_ c: DemoCourse) -> some View {
        VStack(alignment:.leading,spacing:7) { Image(systemName:c.icon).foregroundStyle(.cyan).font(.title2); Text(c.title).font(.headline); Text("\(c.sections) разделов · \(c.materials) материалов").font(.caption).foregroundStyle(.white.opacity(0.6)); if let task=c.task { Label(task,systemImage:"target").font(.caption2).foregroundStyle(.mint) } }
            .frame(width:210,height:105,alignment:.leading).padding(14).background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(.cyan.opacity(0.3))).foregroundStyle(.white)
    }

    private func materialCard(_ m: DemoMaterial) -> some View {
        HStack(spacing:12) { Image(systemName:m.kind == "Опросник" ? "questionmark.bubble.fill":"tablecells.fill").font(.title2).foregroundStyle(.mint); VStack(alignment:.leading,spacing:4) { Text(m.title).font(.headline); Text(m.description).font(.caption).foregroundStyle(.white.opacity(0.62)).lineLimit(2); Text("\(m.kind) · \(m.count) · \(m.source)").font(.caption2).foregroundStyle(.cyan.opacity(0.85)) }; Spacer(); Menu { Button("Добавить в курс"){}; Button("Создать задание"){}; Button("Удалить из библиотеки",role:.destructive){} } label:{Image(systemName:"ellipsis").padding(8)} }
            .padding(13).background(.black.opacity(0.22),in:RoundedRectangle(cornerRadius:16)).foregroundStyle(.white)
            .contentShape(Rectangle()).onTapGesture { selectedMaterial = m }
    }

    private func recordCard(_ m: StudyMaterialRecord) -> some View { HStack { Image(systemName:"tablecells").foregroundStyle(.mint); VStack(alignment:.leading,spacing:4){Text(m.title).font(.headline);if let d=m.description {Text(d).font(.caption).foregroundStyle(.white.opacity(0.62)).lineLimit(2)};if let tags=m.topic {Text(tags).font(.caption2).foregroundStyle(.cyan)}};Spacer();Image(systemName:"chevron.right").foregroundStyle(.white.opacity(0.3)) }.padding(13).background(.black.opacity(0.22),in:RoundedRectangle(cornerRadius:16)).foregroundStyle(.white).contentShape(Rectangle()).onTapGesture{selectedRecord=m} }

    private var groups: some View { VStack(spacing:14) { Text("Назначено преподавателем или родителем").font(.caption).foregroundStyle(.white.opacity(0.55)).frame(maxWidth:.infinity,alignment:.leading); ForEach(demo.groups) { g in VStack(alignment:.leading,spacing:10) { HStack { Image(systemName:"person.3.fill").foregroundStyle(.purple); VStack(alignment:.leading){Text(g.title).font(.headline);Text(g.owner).font(.caption).foregroundStyle(.white.opacity(0.55))};Spacer();Image(systemName:"lock.fill").foregroundStyle(.white.opacity(0.4)) }; Divider().overlay(.white.opacity(0.1)); Label(g.task,systemImage:"target").foregroundStyle(.mint); Text("\(g.materials) материалов · цель задаёт руководитель").font(.caption).foregroundStyle(.white.opacity(0.6)) }.padding(15).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:18)).foregroundStyle(.white) } } }
}


private struct MaterialDetailView: View {
    let material: DemoMaterial
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                DigitalHubBackground()
                ScrollView { VStack(alignment: .leading, spacing: 18) {
                    HStack { Label(material.kind.uppercased(), systemImage: material.kind == "Опросник" ? "questionmark.bubble.fill" : "tablecells.fill"); Spacer(); Text(material.source) }.font(.caption.bold()).foregroundStyle(.cyan)
                    Text(material.title).font(.title2.bold()).foregroundStyle(.white)
                    Text(material.description).foregroundStyle(.white.opacity(0.68))
                    HStack { stat(material.count, "Содержимое"); stat(material.subject, "Предмет") }
                    detailBlock
                    sampleBlock
                    Button("Начать заниматься") {}.buttonStyle(.borderedProminent).tint(.cyan).frame(maxWidth: .infinity)
                }.padding(18) }
            }.navigationTitle("Материал").navigationBarTitleDisplayMode(.inline).toolbar { Button("Готово") { dismiss() } }
        }
    }
    private func stat(_ value:String,_ label:String)->some View { VStack(alignment:.leading,spacing:3){Text(value).font(.headline).foregroundStyle(.white);Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))}.frame(maxWidth:.infinity,alignment:.leading).padding(12).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:14)) }
    private var detailBlock: some View { VStack(alignment:.leading,spacing:10){Text(material.kind == "Справочник" ? "КАК ФОРМИРУЮТСЯ ВОПРОСЫ" : "ТИПЫ ВОПРОСОВ").font(.caption.bold()).foregroundStyle(.cyan);ForEach(material.details,id:\.self){Label($0,systemImage:"checkmark.circle.fill").foregroundStyle(.white)}} }
    private var sampleBlock: some View { VStack(alignment:.leading,spacing:10){Text("ПРИМЕР СОДЕРЖИМОГО").font(.caption.bold()).foregroundStyle(.cyan);ForEach(material.sample,id:\.self){Text($0).frame(maxWidth:.infinity,alignment:.leading).padding(12).background(.black.opacity(0.22),in:RoundedRectangle(cornerRadius:14)).foregroundStyle(.white)}} }
}


private struct SavedMaterialDetailView: View {
    let material: StudyMaterialRecord
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var indices: [UUID: Int] = [:]
    @State private var confirmDelete = false
    @State private var deleteError: String?
    private var content: MaterialContent? { store.content(id: material.id) }
    var body: some View {
        NavigationStack { ZStack { DigitalHubBackground()
            if let c = content { ScrollView { VStack(alignment: .leading, spacing: 16) {
                Text(c.material.title).font(.title2.bold()).foregroundStyle(.white)
                if let d = c.material.description { Text(d).foregroundStyle(.white.opacity(0.7)) }
                HStack { Label("Вы", systemImage: "person.crop.circle"); Spacer(); Text("\(c.rows.count) знаний · \(c.rules.count) наборов · \(c.rows.count * c.rules.count) вопросов") }.font(.caption).foregroundStyle(.cyan)
                if let tags = c.material.topic { Text(tags).font(.caption.bold()).foregroundStyle(.cyan).padding(.horizontal, 10).padding(.vertical, 6).background(.cyan.opacity(0.12), in: Capsule()) }
                ForEach(c.rules) { rule in ruleCard(rule, c) }
            }.padding(18) } } else { ContentUnavailableView("Материал не найден", systemImage: "exclamationmark.triangle") }
        }.navigationTitle("Просмотр").navigationBarTitleDisplayMode(.inline).toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Готово") { dismiss() } }
            ToolbarItem(placement: .primaryAction) { Button(role: .destructive) { confirmDelete = true } label: { Image(systemName: "trash") }.tint(.red) }
        }
        .sheet(isPresented: $confirmDelete) { DeleteMaterialSheet(title: material.title) { deleteMaterial() } }
        .alert("Не удалось удалить материал", isPresented: Binding(get: { deleteError != nil }, set: { if !$0 { deleteError = nil } })) { Button("OK", role: .cancel) {} } message: { Text(deleteError ?? "Неизвестная ошибка") }
        }
    }
    private func ruleCard(_ rule: QuestionRule, _ c: MaterialContent) -> some View {
        let i = min(indices[rule.id] ?? 0, max(c.rows.count - 1, 0)); let row = c.rows.isEmpty ? nil : c.rows[i]
        return VStack(alignment: .leading, spacing: 11) {
            HStack { Text("НАБОР ВОПРОСОВ").font(.caption.bold()).foregroundStyle(.cyan); Spacer(); Text("\(c.rows.count) вопросов").font(.caption).foregroundStyle(.white.opacity(0.5)) }
            Text(render(rule.promptTemplate, rule.promptFieldKeys, row)).font(.headline).foregroundStyle(.white).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 14))
            ForEach(Array(rule.answers.enumerated()), id: \.offset) { _, a in HStack { Image(systemName: a.correct ? "checkmark.circle.fill" : "circle").foregroundStyle(a.correct ? Color.green : Color.white.opacity(0.35)); Text(render(a.template, a.fieldKeys, row)).foregroundStyle(.white) }.padding(.horizontal, 8) }
            if c.rows.count > 1 { HStack { Button { indices[rule.id] = max(0, i-1) } label: { Image(systemName: "chevron.left") }.disabled(i == 0); Spacer(); Text("\(i+1) / \(c.rows.count)").font(.caption).foregroundStyle(.white.opacity(0.6)); Spacer(); Button { indices[rule.id] = min(c.rows.count-1, i+1) } label: { Image(systemName: "chevron.right") }.disabled(i == c.rows.count-1) }.foregroundStyle(.cyan) }
        }.padding(15).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.cyan.opacity(0.2)))
    }
    private func deleteMaterial() { do { try store.delete(id: material.id); dismiss() } catch { deleteError = error.localizedDescription } }
    private func render(_ template: String, _ keys: [String], _ row: KnowledgeRow?) -> String { var x = template; for (i,k) in keys.enumerated() { x = x.replacingOccurrences(of: "{\(i+1)}", with: row?.values[k] ?? "—") }; return x }
}


private struct DeleteMaterialSheet: View {
    let title: String
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack { DigitalHubBackground(); VStack(spacing: 18) {
            ZStack { Circle().fill(.red.opacity(0.14)).frame(width: 70, height: 70); Image(systemName: "trash.fill").font(.system(size: 28)).foregroundStyle(.red) }
            Text("Удалить материал?").font(.title2.bold()).foregroundStyle(.white)
            Text(title).font(.headline).foregroundStyle(.cyan).multilineTextAlignment(.center)
            Text("Материал и все его вопросы будут удалены без возможности восстановления.").font(.subheadline).foregroundStyle(.white.opacity(0.65)).multilineTextAlignment(.center)
            Button(role: .destructive) { dismiss(); onDelete() } label: { Label("Удалить", systemImage: "trash").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10) }.buttonStyle(.borderedProminent).tint(.red)
            Button("Отмена") { dismiss() }.font(.headline).foregroundStyle(.cyan).frame(maxWidth: .infinity).padding(.vertical, 8)
        }.padding(24) }.presentationDetents([.height(390)]).presentationDragIndicator(.visible).presentationCornerRadius(28)
    }
}

private struct AddMaterialSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var create = false
    @State private var savedMaterial = false
    var body: some View { NavigationStack { ZStack { DigitalHubBackground(); ScrollView { VStack(spacing:14) { sourceCard("Импортировать файл","CSV / TSV · создать материал из таблицы","square.and.arrow.down") { create=true }; NavigationLink { PlaceholderSource(title:"Общая библиотека") } label:{ sourceLabel("Общая библиотека","Найти готовые материалы","books.vertical") }; NavigationLink { PlaceholderSource(title:"Создать вручную") } label:{ sourceLabel("Создать вручную","Новый материал без файла","square.and.pencil") }; NavigationLink { PlaceholderSource(title:"Подключиться к классу или группе") } label:{ sourceLabel("Класс или группа","Материалы преподавателя или родителя","person.3") } }.padding(16) } }.navigationTitle("Добавить").toolbar{Button("Готово"){dismiss()}}.sheet(isPresented:$create,onDismiss:{ if savedMaterial { dismiss() } }){AddMaterialView(onSaved:{ savedMaterial=true; create=false })} } }
    private func sourceCard(_ title:String,_ subtitle:String,_ icon:String,action:@escaping()->Void)->some View { Button(action:action){sourceLabel(title,subtitle,icon)} }
    private func sourceLabel(_ title:String,_ subtitle:String,_ icon:String)->some View { HStack(spacing:14){Image(systemName:icon).font(.title2).foregroundStyle(.cyan).frame(width:34);VStack(alignment:.leading,spacing:4){Text(title).font(.headline).foregroundStyle(.white);Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.55))};Spacer();Image(systemName:"chevron.right").foregroundStyle(.white.opacity(0.3))}.padding(16).background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(.cyan.opacity(0.18))) }
}
private struct PlaceholderSource: View { let title:String; var body:some View { ContentUnavailableView(title,systemImage:"hammer.fill",description:Text("Интерфейс предусмотрен. Реализация будет добавлена следующим этапом.")) } }
private struct HubChip: ButtonStyle { let selected:Bool; func makeBody(configuration:Configuration)->some View{configuration.label.font(.caption.bold()).padding(.horizontal,13).padding(.vertical,8).background(selected ? Color.cyan.opacity(0.25):Color.white.opacity(0.06),in:Capsule()).overlay(Capsule().stroke(selected ? Color.cyan.opacity(0.7):Color.white.opacity(0.1))).foregroundStyle(.white)} }
private struct DigitalHubBackground: View { var body:some View{LinearGradient(colors:[Color(red:0.015,green:0.035,blue:0.12),Color(red:0.03,green:0.08,blue:0.18),.black],startPoint:.top,endPoint:.bottom).ignoresSafeArea()} }
