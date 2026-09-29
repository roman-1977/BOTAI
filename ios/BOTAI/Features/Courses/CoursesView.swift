import SwiftUI

struct LearningGoalItem: Identifiable {
    enum Source { case autoCourse, teacher, personal }
    enum State { case active, paused, waiting, completed }
    let id = UUID(); let title: String; let subtitle: String; let source: Source
    var state: State; var progress: Double; let detail: String
}

struct AutoCourseStep: Identifiable {
    let id = UUID(); let number: Int; let title: String; let material: String
    var progress: Double; var unlocked: Bool; var completed: Bool
}

struct CoursesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var goals: [LearningGoalItem] = [
        .init(title:"Оксиды", subtitle:"ЕГЭ Химия · автокурс", source:.autoCourse, state:.active, progress:0.61, detail:"Освоить материал не менее чем на 85%"),
        .init(title:"Кислоты и кислотные остатки", subtitle:"11Б · Анна Сергеевна", source:.teacher, state:.active, progress:0.40, detail:"Задание преподавателя · до 3 октября"),
        .init(title:"Таблица растворимости", subtitle:"Моя цель", source:.personal, state:.paused, progress:0.28, detail:"Без срока · продолжить когда удобно")
    ]
    @State private var showCourse = false
    @State private var showNewGoal = false

    var body: some View {
        NavigationStack {
            ZStack { CourseBackground(); ScrollView { VStack(spacing:16) { summary; activeGoals; courseCard; personalCard }.padding(16) } }
                .navigationTitle("Обучение")
                .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Готово") { dismiss() } } }
                .sheet(isPresented:$showCourse) { AutoCourseView() }
                .sheet(isPresented:$showNewGoal) { NewPersonalGoalView { title in goals.append(.init(title:title,subtitle:"Моя цель",source:.personal,state:.active,progress:0,detail:"Самостоятельная цель")) } }
        }
    }

    private var summary: some View { VStack(alignment:.leading,spacing:8) { Text("ТВОЙ МАРШРУТ").font(.caption.bold()).foregroundStyle(.cyan); Text("Цели из разных источников — в одном месте").font(.title3.bold()).foregroundStyle(.white); Text("Автокурс ведёт по готовой последовательности, преподаватель назначает цели лично, свои цели ты управляешь сам.").font(.subheadline).foregroundStyle(.white.opacity(0.7)) }.frame(maxWidth:.infinity,alignment:.leading).padding(16).background(.black.opacity(0.28),in:RoundedRectangle(cornerRadius:22)).overlay(RoundedRectangle(cornerRadius:22).stroke(.cyan.opacity(0.3))) }

    private var activeGoals: some View { VStack(alignment:.leading,spacing:10) { Text("ЦЕЛИ").font(.caption.bold()).foregroundStyle(.cyan); ForEach($goals) { $goal in GoalSourceCard(goal:$goal) } }.frame(maxWidth:.infinity,alignment:.leading) }

    private var courseCard: some View { Button { showCourse=true } label: { HStack(spacing:12) { Image(systemName:"point.topleft.down.to.point.bottomright.curvepath.fill").font(.title2).foregroundStyle(.cyan); VStack(alignment:.leading,spacing:4) { Text("ЕГЭ Химия 2027").font(.headline); Text("Автокурс · 2 из 8 целей · следующая открывается автоматически").font(.caption).foregroundStyle(.white.opacity(0.65)) }; Spacer(); Image(systemName:"chevron.right") }.foregroundStyle(.white).padding(15).background(.blue.opacity(0.12),in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(.blue.opacity(0.35))) }.buttonStyle(.plain) }

    private var personalCard: some View { Button { showNewGoal=true } label: { Label("ПОСТАВИТЬ СВОЮ ЦЕЛЬ",systemImage:"plus.circle.fill").font(.headline).frame(maxWidth:.infinity).frame(height:48).foregroundStyle(.white).background(.white.opacity(0.06),in:RoundedRectangle(cornerRadius:16)).overlay(RoundedRectangle(cornerRadius:16).stroke(.cyan.opacity(0.35))) }.buttonStyle(.plain) }
}

private struct GoalSourceCard: View {
    @Binding var goal: LearningGoalItem
    private var source: (String,String,Color) { switch goal.source { case .autoCourse:return("АВТОКУРС","arrow.triangle.branch",.cyan);case .teacher:return("ПРЕПОДАВАТЕЛЬ","person.fill.checkmark",.orange);case .personal:return("МОЯ ЦЕЛЬ","person.crop.circle",.mint) } }
    var body: some View { VStack(alignment:.leading,spacing:9) { HStack { Label(source.0,systemImage:source.1).font(.caption.bold()).foregroundStyle(source.2); Spacer(); Text(stateText).font(.caption.bold()).foregroundStyle(goal.state == .paused ? .yellow : .white.opacity(0.65)) }; Text(goal.title).font(.headline).foregroundStyle(.white); Text(goal.subtitle).font(.caption).foregroundStyle(.white.opacity(0.65)); ProgressView(value:goal.progress).tint(source.2); HStack { Text("\(Int(goal.progress*100))%").font(.caption.bold()).foregroundStyle(source.2); Text(goal.detail).font(.caption2).foregroundStyle(.white.opacity(0.58)).lineLimit(1); Spacer(); if goal.source == .personal { Button(goal.state == .paused ? "Продолжить":"Пауза") { goal.state = goal.state == .paused ? .active:.paused }.buttonStyle(.bordered).controlSize(.small) } } }.padding(14).background(.black.opacity(0.27),in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(source.2.opacity(0.28))) }
    private var stateText:String { switch goal.state {case .active:"АКТИВНА";case .paused:"ПАУЗА";case .waiting:"ОЖИДАЕТ";case .completed:"ВЫПОЛНЕНА"} }
}

private struct AutoCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var steps:[AutoCourseStep] = [
        .init(number:1,title:"Химические элементы",material:"Символы и названия · ≥ 90%",progress:1,unlocked:true,completed:true),
        .init(number:2,title:"Оксиды",material:"Формулы и классы · ≥ 85%",progress:0.61,unlocked:true,completed:false),
        .init(number:3,title:"Кислоты",material:"Названия ↔ формулы · ≥ 85%",progress:0,unlocked:false,completed:false),
        .init(number:4,title:"Основания",material:"Формулы и свойства · ≥ 85%",progress:0,unlocked:false,completed:false),
        .init(number:5,title:"Соли",material:"Названия ↔ формулы · ≥ 85%",progress:0,unlocked:false,completed:false),
        .init(number:6,title:"Смешанное повторение",material:"Цели 1–5 · ≥ 90%",progress:0,unlocked:false,completed:false)
    ]
    var body:some View { NavigationStack { ZStack { CourseBackground(); ScrollView { VStack(alignment:.leading,spacing:14) { Text("ЕГЭ Химия 2027").font(.title2.bold()).foregroundStyle(.white); Text("Автокурс").font(.caption.bold()).foregroundStyle(.cyan); Text("Последовательность рассчитана на среднего ученика. Следующая цель открывается после выполнения критерия текущей.").font(.subheadline).foregroundStyle(.white.opacity(0.7)); ForEach(steps) { step in HStack(spacing:12) { ZStack { Circle().fill(step.completed ? .mint.opacity(0.22) : step.unlocked ? .cyan.opacity(0.18):.white.opacity(0.04)); Text(step.completed ? "✓":"\(step.number)").font(.headline.bold()).foregroundStyle(step.unlocked ? .white:.white.opacity(0.35)) }.frame(width:42,height:42); VStack(alignment:.leading,spacing:4) { Text(step.title).font(.headline).foregroundStyle(step.unlocked ? .white:.white.opacity(0.4)); Text(step.material).font(.caption).foregroundStyle(.white.opacity(step.unlocked ? 0.62:0.3)); if step.unlocked && !step.completed { ProgressView(value:step.progress).tint(.cyan) } }; Spacer(); Image(systemName:step.completed ? "checkmark.seal.fill":step.unlocked ? "play.circle.fill":"lock.fill").foregroundStyle(step.completed ? .mint:step.unlocked ? .cyan:.white.opacity(0.25)) }.padding(13).background(.black.opacity(0.25),in:RoundedRectangle(cornerRadius:17)) } }.padding(16) } }.navigationTitle("Курс").navigationBarTitleDisplayMode(.inline).toolbar { Button("Готово") { dismiss() } } } }
}

private struct NewPersonalGoalView: View {
    @Environment(\.dismiss) private var dismiss; @State private var title=""; let onCreate:(String)->Void
    var body:some View { NavigationStack { Form { Section("Своя цель") { TextField("Например: выучить таблицу растворимости",text:$title); Text("Материалы и критерий выполнения подключим следующим шагом. Сейчас создаётся оболочка самостоятельной цели.").font(.caption).foregroundStyle(.secondary) } } .navigationTitle("Новая цель").toolbar { ToolbarItem(placement:.cancellationAction){Button("Отмена"){dismiss()}};ToolbarItem(placement:.confirmationAction){Button("Создать"){let t=title.trimmingCharacters(in:.whitespacesAndNewlines);onCreate(t);dismiss()}.disabled(title.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)} } } }
}

private struct CourseBackground: View { var body: some View { LinearGradient(colors:[Color(red:0.015,green:0.035,blue:0.12),Color(red:0.03,green:0.08,blue:0.18),.black],startPoint:.top,endPoint:.bottom).ignoresSafeArea() } }
