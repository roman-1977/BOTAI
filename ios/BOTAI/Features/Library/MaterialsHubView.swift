import SwiftUI

struct MaterialsHubView: View {
    @Environment(MaterialStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var scope = 0
    @State private var filter = "Все"
    @State private var addMaterial = false

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
    }

    private func recordCard(_ m: StudyMaterialRecord) -> some View { HStack { Image(systemName:"tablecells").foregroundStyle(.mint); VStack(alignment:.leading){Text(m.title).font(.headline);Text([m.subject,m.topic].compactMap{$0}.joined(separator:" · ")).font(.caption).foregroundStyle(.white.opacity(0.6))};Spacer();Image(systemName:"ellipsis") }.padding(13).background(.black.opacity(0.22),in:RoundedRectangle(cornerRadius:16)).foregroundStyle(.white) }

    private var groups: some View { VStack(spacing:14) { Text("Назначено преподавателем или родителем").font(.caption).foregroundStyle(.white.opacity(0.55)).frame(maxWidth:.infinity,alignment:.leading); ForEach(demo.groups) { g in VStack(alignment:.leading,spacing:10) { HStack { Image(systemName:"person.3.fill").foregroundStyle(.purple); VStack(alignment:.leading){Text(g.title).font(.headline);Text(g.owner).font(.caption).foregroundStyle(.white.opacity(0.55))};Spacer();Image(systemName:"lock.fill").foregroundStyle(.white.opacity(0.4)) }; Divider().overlay(.white.opacity(0.1)); Label(g.task,systemImage:"target").foregroundStyle(.mint); Text("\(g.materials) материалов · цель задаёт руководитель").font(.caption).foregroundStyle(.white.opacity(0.6)) }.padding(15).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:18)).foregroundStyle(.white) } } }
}

private struct AddMaterialSourceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var create = false
    var body: some View { NavigationStack { List { Section("Добавить материал") { Button { create=true } label:{Label("Импортировать файл",systemImage:"square.and.arrow.down")}; NavigationLink { PlaceholderSource(title:"Общая библиотека") } label:{Label("Найти в общей библиотеке",systemImage:"books.vertical")}; NavigationLink { PlaceholderSource(title:"Создать вручную") } label:{Label("Создать вручную",systemImage:"square.and.pencil")} }; Section("Группы") { NavigationLink { PlaceholderSource(title:"Подключиться к классу или группе") } label:{Label("Подключиться",systemImage:"person.3")} } }.navigationTitle("Добавить").toolbar{Button("Готово"){dismiss()}}.sheet(isPresented:$create){AddMaterialView()} } }
}
private struct PlaceholderSource: View { let title:String; var body:some View { ContentUnavailableView(title,systemImage:"hammer.fill",description:Text("Интерфейс предусмотрен. Реализация будет добавлена следующим этапом.")) } }
private struct HubChip: ButtonStyle { let selected:Bool; func makeBody(configuration:Configuration)->some View{configuration.label.font(.caption.bold()).padding(.horizontal,13).padding(.vertical,8).background(selected ? Color.cyan.opacity(0.25):Color.white.opacity(0.06),in:Capsule()).overlay(Capsule().stroke(selected ? Color.cyan.opacity(0.7):Color.white.opacity(0.1))).foregroundStyle(.white)} }
private struct DigitalHubBackground: View { var body:some View{LinearGradient(colors:[Color(red:0.015,green:0.035,blue:0.12),Color(red:0.03,green:0.08,blue:0.18),.black],startPoint:.top,endPoint:.bottom).ignoresSafeArea()} }
