import SwiftUI

/// Semantic palette for the existing dark learning/home experience.
/// Components should use roles rather than scattering literal RGB values.
enum HomeTheme {
  static let accent = Color(red: 0.45, green: 0.77, blue: 1.0)
  static let success = Color(red: 0.36, green: 0.83, blue: 0.69)
  static let canvasTop = Color(red: 0.06, green: 0.10, blue: 0.19)
  static let canvasMiddle = Color(red: 0.09, green: 0.15, blue: 0.25)
  static let canvasBottom = Color(red: 0.04, green: 0.07, blue: 0.13)
  static let surface = Color(red: 0.11, green: 0.17, blue: 0.27)
  static let muted = Color.white.opacity(0.72)
  static let separator = Color.white.opacity(0.14)
  static let warning = Color(red: 0.98, green: 0.74, blue: 0.38)
  static let error = Color(red: 0.97, green: 0.46, blue: 0.52)
}

struct GameHomeView: View {
  @Environment(LearningStore.self) private var learning
  @Environment(MaterialStore.self) private var materials
  @Environment(CourseStore.self) private var courses
  @Environment(StudyProfileStore.self) private var profile
  @State private var learn = false
  @State private var profileOpen = false
  @State private var materialsOpen = false
  @State private var coursesOpen = false
  @State private var chooseGoal = false
  private var plan: DailyStudyPlan {
    DailyPlanner.make(
      courses: courses.courses, materials: materials, learning: learning, profile: profile.profile)
  }
  var body: some View {
    NavigationStack {
      ZStack {
        DigitalBackground()
        ScrollView(showsIndicators: false) {
          VStack(spacing: 14) {
            topBar
            todayCard
            if !plan.goals.isEmpty { goalsCard }
            progressCard
            launch
          }.padding(.horizontal, 14).padding(.bottom, 26)
        }
      }.toolbar(.hidden, for: .navigationBar).confirmationDialog(
        "Что изучать?", isPresented: $chooseGoal, titleVisibility: .visible
      ) {
        ForEach(plan.goals) { g in Button("\(g.title) · \(g.questions.count) вопросов") { start(g) }
        }
        Button("Отмена", role: .cancel) {}
      }.sheet(
        isPresented: $learn,
        onDismiss: {
          GoalProgressService.reconcile(courses: courses, materials: materials, learning: learning)
        }
      ) { LearnSessionView() }.sheet(isPresented: $profileOpen) {
        NavigationStack { ProfileView() }
      }.sheet(isPresented: $materialsOpen) { MaterialsHubView() }.sheet(isPresented: $coursesOpen) {
        CoursesView()
      }
    }
  }
  private var topBar: some View {
    HStack {
      Text("BOTAI").font(.title2.bold()).foregroundStyle(HomeTheme.accent)
      Spacer()
      if learning.streak > 0 {
        Label("\(learning.streak) дн.", systemImage: "flame.fill").foregroundStyle(.orange)
      }
      Button {
        coursesOpen = true
      } label: {
        Image(systemName: "flag.checkered").font(.title2)
      }.accessibilityLabel("Мои курсы")
      Button {
        materialsOpen = true
      } label: {
        Image(systemName: "books.vertical.fill").font(.title2)
      }.accessibilityLabel("Материалы")
      Button {
        profileOpen = true
      } label: {
        Image(systemName: "person.crop.circle.fill").font(.title2)
      }.accessibilityLabel("Профиль")
    }.padding(.top, 8)
  }
  private var todayCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("ПЛАН НА СЕГОДНЯ").font(.caption.bold()).foregroundStyle(HomeTheme.accent)
          Text(
            plan.budgetMinutes == 0
              ? "Сегодня день отдыха" : "\(plan.budgetMinutes) минут на обучение"
          ).font(.title2.bold()).foregroundStyle(.white)
          Text(
            plan.goals.isEmpty ? emptyPlanText : "BOTAI распределил время между текущими целями."
          ).font(.caption).foregroundStyle(HomeTheme.muted)
        }
        Spacer()
        ZStack {
          Circle().stroke(.white.opacity(0.1), lineWidth: 8)
          Circle().trim(
            from: 0, to: min(1, Double(todayMinutes) / Double(max(1, plan.budgetMinutes)))
          ).stroke(HomeTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .rotationEffect(.degrees(-90))
          Text("\(todayMinutes)").font(.headline.bold()).foregroundStyle(.white)
        }.frame(width: 70, height: 70)
      }
    }.padding(16).homeCard()
  }
  private var goalsCard: some View {
    VStack(alignment: .leading, spacing: 11) {
      Text("СЕГОДНЯ ПО ЦЕЛЯМ").font(.caption.bold()).foregroundStyle(HomeTheme.accent)
      ForEach(plan.goals) { g in
        VStack(spacing: 6) {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(g.title).font(.headline)
              if let d = g.deadline {
                Text("до \(d.formatted(date:.abbreviated,time:.omitted))").font(.caption).opacity(
                  0.75)
              }
            }
            Spacer()
            Text("\(g.minutes) мин").font(.headline).foregroundStyle(HomeTheme.accent)
          }
          HStack {
            Text("Освоено \(g.mastery)%").font(.caption)
            Spacer()
            Text("цель \(g.target)%").font(.caption)
          }.foregroundStyle(.white.opacity(0.6))
          GeometryReader { geo in
            ZStack(alignment: .leading) {
              Capsule().fill(.white.opacity(0.08))
              Capsule().fill(HomeTheme.success).frame(
                width: geo.size.width * CGFloat(g.mastery) / 100)
            }
          }.frame(height: 7)
        }.foregroundStyle(.white)
      }
    }.padding(16).homeCard()
  }
  private var progressCard: some View {
    HStack(spacing: 8) {
      HomeMetric(value: "\(learning.masteryPercent)%", label: "ОСВОЕНО")
      HomeMetric(value: "\(learning.dueCount)", label: "ПОВТОРИТЬ")
      HomeMetric(value: timeText(learning.analytics.totalSeconds), label: "ВСЕГО")
    }.padding(12).homeCard()
  }
  private var launch: some View {
    VStack(spacing: 9) {
      Button {
        startPlan()
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "play.fill").font(.title2).foregroundStyle(.white).frame(
            width: 52, height: 52
          ).background(.white.opacity(0.16), in: Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text("УЧИТЬСЯ СЕГОДНЯ").font(.headline)
            Text(launchSubtitle).font(.caption).opacity(0.72)
          }
          Spacer()
          Image(systemName: "chevron.right")
        }.foregroundStyle(.white).padding(.horizontal, 14).frame(height: 78).background(
          LinearGradient(
            colors: [HomeTheme.accent.opacity(0.9), .blue.opacity(0.88), .purple.opacity(0.7)],
            startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 22))
      }.buttonStyle(.plain)
        .disabled(plan.questions.isEmpty)
        .accessibilityHint(plan.questions.isEmpty ? "Сначала выберите учебную цель" : "Начать занятия по плану")
      if plan.questions.isEmpty {
        Button(launchActionTitle) { coursesOpen = true }.buttonStyle(.bordered).tint(
          HomeTheme.accent)
      }
    }
  }
  private var todayMinutes: Int {
    learning.sessions.filter { Calendar.current.isDateInToday($0.startedAt) }.reduce(0) {
      $0 + $1.activeSeconds
    } / 60
  }
  private var emptyPlanText: String {
    if plan.budgetMinutes == 0 { return "В профиле на этот день установлено 0 минут." }
    if courses.courses.flatMap(\.goals).isEmpty {
      return "Создай цель в курсе — она определит, что изучать."
    }
    if !activeGoals.isEmpty { return "Активная цель есть, но в ней нет доступных вопросов." }
    return
      "Выбери запланированную цель и один раз нажми «Начать». После этого ежедневные занятия запускаются отсюда."
  }
  private var activeGoals: [LearningGoal] {
    courses.courses.flatMap(\.goals).filter { $0.state == .active }
  }
  private var launchSubtitle: String {
    if !plan.questions.isEmpty {
      return "\(plan.questions.count) вопросов · план \(plan.plannedMinutes) мин"
    }
    if plan.budgetMinutes == 0 { return "Сегодня по расписанию день отдыха" }
    if !activeGoals.isEmpty { return "В активной цели пока нет доступных вопросов" }
    return "Сначала один раз запусти учебную цель"
  }
  private var launchActionTitle: String {
    activeGoals.isEmpty ? "Выбрать цель и начать" : "Проверить содержание цели"
  }
  private func startPlan() {
    if plan.goals.count == 1, let g = plan.goals.first { start(g) } else { chooseGoal = true }
  }
  private func start(_ g: DailyStudyPlan.GoalPlan) {
    learning.use(questions: g.questions.shuffled(), title: g.title, targetMinutes: g.minutes)
    learn = true
  }
  private func timeText(_ seconds: Int) -> String {
    let m = seconds / 60
    if m < 60 { return "\(m) мин" }
    return "\(m/60)ч \(m%60)м"
  }
}

struct DigitalBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [HomeTheme.canvasTop, HomeTheme.canvasMiddle, HomeTheme.canvasBottom],
        startPoint: .top, endPoint: .bottom
      ).ignoresSafeArea()
      Canvas { c, s in
        for x in stride(from: 0.0, through: s.width, by: 32) {
          var p = Path()
          p.move(to: .init(x: x, y: 0))
          p.addLine(to: .init(x: x, y: s.height))
          c.stroke(p, with: .color(HomeTheme.accent.opacity(0.035)))
        }
        for y in stride(from: 0.0, through: s.height, by: 32) {
          var p = Path()
          p.move(to: .init(x: 0, y: y))
          p.addLine(to: .init(x: s.width, y: y))
          c.stroke(p, with: .color(HomeTheme.accent.opacity(0.035)))
        }
      }.ignoresSafeArea()
    }
  }
}
private struct HomeMetric: View {
  let value: String
  let label: String
  var body: some View {
    VStack(spacing: 4) {
      Text(value).font(.headline.bold()).foregroundStyle(.white)
      Text(label).font(.caption2.weight(.semibold)).foregroundStyle(HomeTheme.accent)
    }.frame(maxWidth: .infinity, minHeight: 58).background(
      .black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
  }
}
extension View {
  fileprivate func homeCard() -> some View {
    background(HomeTheme.surface, in: RoundedRectangle(cornerRadius: 22)).overlay(
      RoundedRectangle(cornerRadius: 22).stroke(HomeTheme.accent.opacity(0.2)))
  }
}
