import SwiftUI
import UIKit
import PDFKit

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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(LearningStore.self) private var learning
  @Environment(MaterialStore.self) private var materials
  @Environment(CourseStore.self) private var courses
  @Environment(StudyProfileStore.self) private var profile
  @State private var learn = false
  @State private var profileOpen = false
  @State private var materialsOpen = false
  @State private var coursesOpen = false
  @State private var chooseGoal = false
  @State private var chooseSession = false
  @State private var reportURL: URL?
  private var plan: DailyStudyPlan {
    DailyPlanner.make(
      courses: courses.courses, materials: materials, learning: learning, profile: profile.profile)
  }
  var body: some View {
    NavigationStack {
      ZStack {
        Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
        GeometryReader { geometry in
          Group {
            if dynamicTypeSize.isAccessibilitySize {
              ScrollView(showsIndicators: false) { homeDashboard.padding(.bottom, 20) }
            } else {
              homeDashboard.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
          }.frame(width: geometry.size.width, height: geometry.size.height)
        }
      }.foregroundStyle(Color.primary).tint(HomePalette.accent)
        .toolbar(.hidden, for: .navigationBar).confirmationDialog(
        "Что изучать?", isPresented: $chooseGoal, titleVisibility: .visible
      ) {
        ForEach(plan.goals) { g in Button("\(g.title) · \(g.questions.count) вопросов") { start(g) }
        }
        Button("Отмена", role: .cancel) {}
      }.sheet(isPresented: $chooseSession) {
        SessionLaunchPicker(courses: courses.courses, materials: materials, learning: learning) { questions, title in
          learning.use(questions: questions.shuffled(), title: title, targetMinutes: plan.budgetMinutes)
          chooseSession = false
          learn = true
        }
      }.sheet(isPresented: Binding(get: { reportURL != nil }, set: { if !$0 { reportURL = nil } })) {
        if let url = reportURL { PDFShareSheet(url: url) }
      }.sheet(
        isPresented: $learn,
        onDismiss: {
          GoalProgressService.reconcile(courses: courses, materials: materials, learning: learning)
          captureForecasts()
        }
      ) { LearnSessionView() }.sheet(isPresented: $profileOpen) {
        NavigationStack { ProfileView() }
      }.sheet(isPresented: $materialsOpen) { MaterialsHubView() }.sheet(isPresented: $coursesOpen) {
        CoursesView()
      }
    }
  }
  /// The standard-size home is a one-screen dashboard; only accessibility text sizes scroll.
  private var homeDashboard: some View {
    VStack(spacing: 9) {
      topBar
      motivationChart
      todayCard
      progressCard
      launch
      motivationInsight
      HStack(spacing: 8) {
        Button("Мои цели") { coursesOpen = true }
        Button("Отчёт PDF") { exportReport() }
      }.buttonStyle(.bordered).tint(HomePalette.accent).font(.caption)
    }.padding(.horizontal, 14).padding(.bottom, 8)
  }
  private var motivationInsight: some View {
    let due = learning.dueCount
    let completed = learning.completedToday
    let message: String = due > 0
      ? "К повторению: \(due). Начни с них — это поможет закрепить знания."
      : completed > 0
        ? "Сегодня отвечено на \(completed) вопросов. Отличная работа!"
        : "Даже короткое занятие сегодня поможет сохранить темп."
    return HStack(spacing: 7) {
      Image(systemName: due > 0 ? "arrow.clockwise.circle" : "sparkle")
        .foregroundStyle(HomePalette.accent)
      Text(message).font(.caption).foregroundStyle(.secondary).lineLimit(2)
      Spacer(minLength: 0)
    }.accessibilityElement(children: .combine)
  }
  private var motivationChart: some View {
    let selectedGoalID = activeGoals.first?.id
    let history = learning.forecastHistory.filter { $0.goalID == selectedGoalID }
      .sorted { $0.calculatedAt < $1.calculatedAt }
    let points = Array(history.suffix(14))
    let latest = points.last
    return VStack(alignment: .leading, spacing: 5) {
      HStack {
        Text("МОЙ ПУТЬ К ЦЕЛИ").font(.caption.bold()).foregroundStyle(HomePalette.accent)
        Spacer()
        if let last = latest, let deadline = activeGoals.first(where: { $0.id == last.goalID })?.deadline,
           let predicted = last.forecastAt {
          let days = Calendar.current.dateComponents([.day], from: deadline, to: predicted).day ?? 0
          Text(days > 0 ? "Отставание: \(days) дн." : days < 0 ? "Опережение: \(-days) дн." : "По графику")
            .font(.caption.bold()).foregroundStyle(days > 0 ? HomePalette.warning : HomePalette.success)
        } else { Text("Прогноз после 3 дней занятий").font(.caption2).foregroundStyle(Color.secondary) }
      }
      GeometryReader { geo in
        let maxValue = max(1, points.map(\.target).max() ?? 1)
        ZStack {
          if let first = points.first, let last = points.last, points.count > 1 {
            let days = max(1, Calendar.current.dateComponents([.day], from: first.calculatedAt, to: last.calculatedAt).day ?? 1)
            let deadline = activeGoals.first(where: { $0.id == selectedGoalID })?.deadline
            let daysToDeadline = max(1, deadline.map { Calendar.current.dateComponents([.day], from: first.calculatedAt, to: $0).day ?? 1 } ?? days)
            let expected = min(Double(last.target), Double(first.known) + Double(last.target - first.known) * Double(days) / Double(daysToDeadline))
            Path { path in
              path.move(to: CGPoint(x: 0, y: geo.size.height * (1 - CGFloat(first.known) / CGFloat(maxValue))))
              path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * (1 - CGFloat(expected) / CGFloat(maxValue))))
            }.stroke(HomePalette.accent, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
          }
          if points.count > 1 {
            Path { path in
              for (index, point) in points.enumerated() {
                let x = geo.size.width * CGFloat(index) / CGFloat(points.count - 1)
                let y = geo.size.height * (1 - CGFloat(point.known) / CGFloat(maxValue))
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
              }
            }.stroke(HomePalette.success, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
          } else {
            Text("История освоения появится после занятий")
              .font(.caption2).foregroundStyle(Color.secondary)
          }
        }
      }.frame(height: 55)
    }.padding(11).lightHomeCard()
  }
  private func exportReport() {
    do {
      captureForecasts()
      reportURL = try StudyPDFReport.export(profile: profile.profile, sessions: learning.sessions,
        attempts: learning.attempts, knowledgeStates: learning.knowledgeStates,
        courses: courses.courses, materials: materials, knowledgeHistory: learning.knowledgeHistory,
        planHistory: profile.history, forecastHistory: learning.forecastHistory)
    } catch { reportError = error.localizedDescription }
  }
  private var topBar: some View {
    HStack {
      Text("BOTAI").font(.title2.bold()).foregroundStyle(HomePalette.accent)
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
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(alignment: .leading, spacing: 12) {
          todayDetails
          HStack {
            Spacer()
            todayProgressRing
          }
        }
      } else {
        HStack(spacing: 12) {
          todayDetails
          Spacer(minLength: 0)
          todayProgressRing
        }
      }
    }.padding(12).lightHomeCard()
  }
  private var todayDetails: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("ПЛАН НА СЕГОДНЯ").font(.caption.bold()).foregroundStyle(HomePalette.accent)
      Text(
        plan.budgetMinutes == 0
          ? "По плану отдых · заниматься можно" : "\(plan.budgetMinutes) минут на обучение"
      ).font(.title2.bold()).foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
      Text(
        plan.goals.isEmpty ? emptyPlanText : "BOTAI распределил время между текущими целями."
      ).font(.caption).foregroundStyle(Color.secondary)
    }
  }
  private var todayProgressRing: some View {
    ZStack {
      Circle().stroke(HomePalette.accent.opacity(0.12), lineWidth: 8)
      Circle().trim(
        from: 0, to: min(1, Double(todayMinutes) / Double(max(1, plan.budgetMinutes)))
      ).stroke(HomePalette.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(todayMinutes)").font(.headline.bold()).foregroundStyle(.primary)
    }.frame(width: 70, height: 70)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Сегодня изучено \(todayMinutes) из \(plan.budgetMinutes) минут")
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
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        VStack(spacing: 8) { progressMetrics }
      } else {
        HStack(spacing: 8) { progressMetrics }
      }
    }.padding(12).lightHomeCard()
  }
  @ViewBuilder
  private var progressMetrics: some View {
    LightHomeMetric(value: "\(learning.masteryPercent)%", label: "ОСВОЕНО")
    LightHomeMetric(value: "\(learning.dueCount)", label: "ПОВТОРИТЬ")
    LightHomeMetric(value: timeText(learning.analytics.totalSeconds), label: "ВСЕГО")
  }
  /// Capture a daily snapshot after a study session and when exporting a report.
  /// Upsert by goal/day avoids duplicate snapshots from repeated visits.
  private func captureForecasts() {
    let today = Date()
    for course in courses.courses {
      for goal in course.goals where goal.state == .active {
        let ids = Set(goal.questionSets.flatMap { ref -> [UUID] in
          guard let content = materials.content(id: ref.materialID) else { return [] }
          return StudyQuestionBuilder.questions(for: ref, content: content).map(\.knowledgeID)
        })
        guard !ids.isEmpty else { continue }
        let forecast = KnowledgeDeadlineForecast.evaluate(goal: goal, knowledgeIDs: ids,
          states: learning.knowledgeStates, history: learning.knowledgeHistory, now: today)
        let day = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: today))
        _ = learning.saveForecast(.init(goalID: goal.id, day: day, calculatedAt: today,
          forecastAt: forecast.estimatedCompletion, known: forecast.currentKnown,
          target: forecast.requiredKnown, rate: forecast.observedPerDay, algorithmVersion: 2))
      }
    }
  }

  private var reportAction: some View {
    Button {
      do {
        captureForecasts()
        reportURL = try StudyPDFReport.export(profile: profile.profile, sessions: learning.sessions,
          attempts: learning.attempts, knowledgeStates: learning.knowledgeStates,
          courses: courses.courses, materials: materials, knowledgeHistory: learning.knowledgeHistory,
          planHistory: profile.history, forecastHistory: learning.forecastHistory)
      } catch { reportError = error.localizedDescription }
    } label: {
      Label("Расширенный отчёт · PDF", systemImage: "doc.richtext")
        .frame(maxWidth: .infinity).padding(12)
    }.buttonStyle(.bordered).tint(HomeTheme.accent)
      .alert("Не удалось создать PDF", isPresented: Binding(get: { reportError != nil }, set: { if !$0 { reportError = nil } })) {
        Button("OK", role: .cancel) { reportError = nil }
      } message: { Text(reportError ?? "") }
  }
  @State private var reportError: String?
  private var launch: some View {
    VStack(spacing: 9) {
      Button {
        chooseSession = true
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "play.fill").font(.title2).foregroundStyle(.white).frame(
            width: 52, height: 52
          ).background(.white.opacity(0.16), in: Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text("БОТАТЬ").font(.headline).lineLimit(2)
            Text(launchSubtitle).font(.caption).opacity(0.72).lineLimit(3)
          }
          Spacer()
          Image(systemName: "chevron.right")
        }.foregroundStyle(.white).padding(.horizontal, 14).frame(minHeight: 78).padding(.vertical, 6).background(
          LinearGradient(
            colors: [HomePalette.accent, HomePalette.accent.opacity(0.88)],
            startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 22))
      }.buttonStyle(.plain)
        .accessibilityIdentifier("primary-study-launch")
        .accessibilityHint("Настроить и начать занятие")
      if plan.questions.isEmpty {
        Button(launchActionTitle) { coursesOpen = true }.buttonStyle(.bordered).tint(
          HomePalette.accent)
      }
    }
  }
  private var todayMinutes: Int {
    learning.sessions.filter { Calendar.current.isDateInToday($0.startedAt) }.reduce(0) {
      $0 + $1.activeSeconds
    } / 60
  }
  private var emptyPlanText: String {
    if plan.budgetMinutes == 0 { return "По расписанию отдых. Любое занятие сегодня — дополнительное достижение." }
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
      return plan.budgetMinutes == 0 ? "\(plan.questions.count) вопросов · вне плана" : "\(plan.questions.count) вопросов · план \(plan.plannedMinutes) мин"
    }
    if plan.budgetMinutes == 0 { return "Можно заниматься вне плана — по своему желанию" }
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
    learning.use(questions: g.questions.shuffled(), title: g.title, targetMinutes: plan.budgetMinutes == 0 ? 0 : g.minutes)
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
      Text(label).font(.caption2.weight(.semibold)).foregroundStyle(HomeTheme.accent).minimumScaleFactor(0.8).lineLimit(2)
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

private struct PDFShareSheet: UIViewControllerRepresentable {
  let url: URL
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [url], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// PDF is rendered locally; no learning data is uploaded.
enum StudyPDFReport {
  @MainActor static func export(profile: StudyProfile, sessions: [StudySession], attempts: [Attempt],
                     knowledgeStates: [UUID: LearningState], courses: [StudyCourse],
                     materials: MaterialStore? = nil, knowledgeHistory: [LearningRepository.KnowledgeProgressEvent] = [],
                     planHistory: [StudyProfile] = [], forecastHistory: [LearningRepository.ForecastSnapshot] = [],
                     now: Date = .now) throws -> URL {
    let calendar = Calendar.current
    let days = (0..<28).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: now)) }
    let totalSeconds = sessions.reduce(0) { $0 + $1.activeSeconds }
    let answered = attempts.count
    let known = knowledgeStates.values.filter { $0.masteryLevel == .known }.count
    let due = knowledgeStates.values.filter { $0.nextDueAt <= now }.count
    let pages: [String] = [
      "BOTAI — РАСШИРЕННЫЙ ОТЧЁТ",
      "Сформирован: \(now.formatted(date: .abbreviated, time: .shortened))",
      "Период: последние 28 дней",
      "Знаний в истории: \(knowledgeStates.count)",
      "Устойчиво освоено: \(known) (\(knowledgeStates.isEmpty ? 0 : known * 100 / knowledgeStates.count)%)",
      "К повторению: \(due)",
      "Ответов за всё время: \(answered)",
      "Учебное время за всё время: \(totalSeconds / 60) минут",
      "Активных целей: \(courses.flatMap(\.goals).filter { $0.state == .active }.count)",
      "",
      "ПЛАН И ФАКТ ПО ДНЯМ",
      "План — ориентир, занятия вне плана учитываются и приветствуются."
    ]
    var lines = pages
    var plannedTotal = 0
    var actualTotal = 0
    for day in days {
      // Use the schedule effective on this historical date, not today's edited plan.
      let historicalProfile = planHistory.filter { $0.updatedAt < calendar.date(byAdding: .day, value: 1, to: day)! }
        .max(by: { $0.updatedAt < $1.updatedAt })
      let planned = (historicalProfile ?? profile).minutes(for: calendar.component(.weekday, from: day))
      let seconds = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }.reduce(0) { $0 + $1.activeSeconds }
      let actual = seconds / 60
      let answers = attempts.filter { calendar.isDate($0.occurredAt, inSameDayAs: day) }.count
      plannedTotal += planned
      actualTotal += actual
      let status = planned == 0 ? (actual > 0 ? "Бонус: вне плана" : "Отдых по плану")
        : (actual >= planned ? "План выполнен" : "Ниже плана")
      lines.append("\(day.formatted(date: .numeric, time: .omitted)): план \(planned) мин, факт \(actual) мин, ответов \(answers) — \(status)")
    }
    lines.insert("За 28 дней: план \(plannedTotal) мин / факт \(actualTotal) мин", at: 12)
    lines.append("")
    lines.append("ИНТЕРПРЕТАЦИЯ")
    if plannedTotal == 0 {
      lines.append(actualTotal > 0 ? "Вы занимались по собственной инициативе. Отличная работа!" : "В расписании отдых. Учиться можно в любой день.")
    } else if actualTotal >= plannedTotal {
      lines.append("План по времени выполнен. Отличная дисциплина!")
    } else {
      lines.append("Есть отставание от плана по времени. Можно начать с короткого занятия сегодня.")
    }
    lines.append("")
    lines.append("ПРОГНОЗ И РЕКОМЕНДАЦИИ")
    let recentDays = days.suffix(14)
    let recentMinutes = recentDays.reduce(0) { total, day in
      total + sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
        .reduce(0) { $0 + $1.activeSeconds } / 60
    }
    let weeklyPace = Double(recentMinutes) / 2.0
    let plannedWeekly = profile.weeklyMinutes
    lines.append("Фактический темп за 14 дней: \(Int(weeklyPace.rounded())) мин/нед.; план: \(plannedWeekly) мин/нед.")
    let delta = Int((weeklyPace - Double(plannedWeekly)).rounded())
    if plannedWeekly > 0 {
      lines.append(delta >= 0
        ? "По времени опережение плана: +\(delta) мин/нед."
        : "По времени отставание от плана: \(abs(delta)) мин/нед.")
      if delta < 0 {
        let shortfall = abs(delta)
        let extraDays = max(1, Int(ceil(Double(shortfall) / 15.0)))
        lines.append("Рекомендация: добавить \(extraDays) коротких занятий по 15 минут в неделю или распределить недостающие \(shortfall) минут между удобными днями.")
      } else {
        lines.append("Рекомендация: сохраняйте устойчивый темп; дополнительные занятия необязательны.")
      }
    } else {
      lines.append("Запланированного времени нет. Занятия по желанию — дополнительный результат.")
    }
    if let materials {
      lines.append("")
      lines.append("ПРОГНОЗ ДОСТИЖЕНИЯ ЦЕЛЕЙ ПО ЗНАНИЯМ")
      for course in courses {
        for goal in course.goals where goal.state == .active {
          let knowledgeIDs = Set(goal.questionSets.flatMap { ref -> [UUID] in
            guard let content = materials.content(id: ref.materialID) else { return [] }
            return StudyQuestionBuilder.questions(for: ref, content: content).map(\.knowledgeID)
          })
          guard !knowledgeIDs.isEmpty else { continue }
          let forecast = KnowledgeDeadlineForecast.evaluate(goal: goal, knowledgeIDs: knowledgeIDs,
            states: knowledgeStates, history: knowledgeHistory, now: now)
          lines.append(contentsOf: forecast.reportLines)
          let snapshots = forecastHistory.filter { $0.goalID == goal.id }.sorted { $0.calculatedAt < $1.calculatedAt }
          if let first = snapshots.first, let last = snapshots.last, snapshots.count >= 2 {
            lines.append("История прогноза: \(snapshots.count) дней наблюдений; освоено \(first.known) → \(last.known).")
            if let earlier = first.forecastAt, let later = last.forecastAt {
              let change = calendar.dateComponents([.day], from: later, to: earlier).day ?? 0
              lines.append(change >= 0 ? "Прогноз улучшился на \(change) дн." : "Прогноз ухудшился на \(abs(change)) дн.")
            }
          }
        }
      }
    }
    lines.append("Показатель освоения рассчитан по знаниям с сохранённым прогрессом, а не по всему учебному курсу.")
    let output = FileManager.default.temporaryDirectory.appendingPathComponent("BOTAI_Study_Report_\(UUID().uuidString).pdf")
    let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
    let data = renderer.pdfData { ctx in
      var y: CGFloat = 45
      ctx.beginPage()
      for (index, line) in lines.enumerated() {
        let font = index == 0 ? UIFont.boldSystemFont(ofSize: 18) : UIFont.systemFont(ofSize: 10)
        let rect = CGRect(x: 38, y: y, width: 520, height: 40)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let box = (line as NSString).boundingRect(with: CGSize(width: 520, height: 100),
          options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        let height = max(16, ceil(box.height) + 4)
        if y + height > 800 { ctx.beginPage(); y = 45 }
        (line as NSString).draw(in: CGRect(x: rect.minX, y: y, width: rect.width, height: height), withAttributes: attrs)
        y += height + (line.isEmpty ? 6 : 2)
      }
    }
    // Add a dedicated visual history page only when at least two daily observations exist.
    let grouped = Dictionary(grouping: forecastHistory, by: \.goalID)
    let chartGroups = grouped.values.filter { $0.count >= 2 }
    if !chartGroups.isEmpty {
      let chartRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
      let chartData = chartRenderer.pdfData { ctx in
        ctx.beginPage()
        let title = "ИСТОРИЯ ПРОГНОЗОВ — ДИНАМИКА ОСВОЕНИЯ"
        (title as NSString).draw(at: CGPoint(x: 38, y: 42), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 15)])
        var top: CGFloat = 95
        for snapshots in chartGroups.sorted(by: { ($0.first?.goalID.uuidString ?? "") < ($1.first?.goalID.uuidString ?? "") }) {
          if top + 260 > 800 { ctx.beginPage(); top = 55 }
          let ordered = snapshots.sorted { $0.calculatedAt < $1.calculatedAt }
          guard let first = ordered.first, let last = ordered.last else { continue }
          let label = courses.flatMap(\.goals).first(where: { $0.id == first.goalID })?.title ?? "Учебная цель"
          ("\(label) · освоено \(first.known) → \(last.known)" as NSString).draw(at: CGPoint(x: 38, y: top),
            withAttributes: [.font: UIFont.systemFont(ofSize: 11)])
          let origin = CGPoint(x: 50, y: top + 115)
          let width: CGFloat = 490, height: CGFloat = 75
          let maxKnown = max(1, ordered.map { max($0.target, $0.known) }.max() ?? 1)
          let dates = ordered.map(\.calculatedAt)
          let span = max(1, dates.last!.timeIntervalSince(dates.first!))
          let context = ctx.cgContext
          context.setStrokeColor(UIColor.systemGray.cgColor)
          context.setLineWidth(0.5)
          context.move(to: CGPoint(x: origin.x, y: origin.y - height))
          context.addLine(to: origin)
          context.addLine(to: CGPoint(x: origin.x + width, y: origin.y))
          context.strokePath()
          context.setStrokeColor(UIColor.systemBlue.cgColor)
          context.setLineWidth(2)
          for (index, item) in ordered.enumerated() {
            let x = origin.x + width * CGFloat(item.calculatedAt.timeIntervalSince(dates.first!) / span)
            let y = origin.y - height * CGFloat(item.known) / CGFloat(maxKnown)
            if index == 0 { context.move(to: CGPoint(x: x, y: y)) }
            else { context.addLine(to: CGPoint(x: x, y: y)) }
          }
          context.strokePath()
          ("\(first.calculatedAt.formatted(date: .numeric, time: .omitted))" as NSString).draw(at: CGPoint(x: origin.x, y: origin.y + 5),
            withAttributes: [.font: UIFont.systemFont(ofSize: 8)])
          ("\(last.calculatedAt.formatted(date: .numeric, time: .omitted))" as NSString).draw(at: CGPoint(x: origin.x + width - 75, y: origin.y + 5),
            withAttributes: [.font: UIFont.systemFont(ofSize: 8)])
          // ETA timeline: days early/late against the goal deadline; no interpolation
          // across missing forecasts (nil means the algorithm had insufficient evidence).
          let deadline = courses.flatMap(\.goals).first(where: { $0.id == first.goalID })?.deadline
          let projected = ordered.compactMap { item -> (Date, Int)? in
            guard let forecast = item.forecastAt, let deadline else { return nil }
            return (item.calculatedAt, calendar.dateComponents([.day], from: deadline, to: forecast).day ?? 0)
          }
          if let deadline, projected.count >= 2 {
            ("Прогноз относительно срока \(deadline.formatted(date: .numeric, time: .omitted)): + отставание / − опережение" as NSString)
              .draw(at: CGPoint(x: 38, y: top + 143), withAttributes: [.font: UIFont.systemFont(ofSize: 9)])
            let maxAbs = max(1, projected.map { abs($0.1) }.max() ?? 1)
            let baseline = top + 211
            let scale: CGFloat = 32 / CGFloat(maxAbs)
            context.setStrokeColor(UIColor.systemGray.cgColor)
            context.setLineWidth(0.6)
            context.move(to: CGPoint(x: origin.x, y: baseline))
            context.addLine(to: CGPoint(x: origin.x + width, y: baseline))
            context.strokePath()
            context.setStrokeColor(UIColor.systemOrange.cgColor)
            context.setLineWidth(2)
            // Each pair is connected only if there were no nil ETA snapshots between them.
            for index in 1..<ordered.count {
              guard let previous = ordered[index - 1].forecastAt,
                    let current = ordered[index].forecastAt else { continue }
              let a = calendar.dateComponents([.day], from: deadline, to: previous).day ?? 0
              let b = calendar.dateComponents([.day], from: deadline, to: current).day ?? 0
              let x0 = origin.x + width * CGFloat(ordered[index - 1].calculatedAt.timeIntervalSince(dates.first!) / span)
              let x1 = origin.x + width * CGFloat(ordered[index].calculatedAt.timeIntervalSince(dates.first!) / span)
              context.move(to: CGPoint(x: x0, y: baseline - CGFloat(a) * scale))
              context.addLine(to: CGPoint(x: x1, y: baseline - CGFloat(b) * scale))
              context.strokePath()
            }
            ("Первый: \(projected.first!.1) дн.; последний: \(projected.last!.1) дн." as NSString)
              .draw(at: CGPoint(x: 38, y: top + 246), withAttributes: [.font: UIFont.systemFont(ofSize: 9)])
          } else {
            ("История прогнозной даты: недостаточно сопоставимых оценок." as NSString)
              .draw(at: CGPoint(x: 38, y: top + 153), withAttributes: [.font: UIFont.systemFont(ofSize: 9)])
          }
          top += 275
        }
      }
      // Merge the text report and chart pages without rasterizing either document.
      if let original = PDFDocument(data: data), let chart = PDFDocument(data: chartData) {
        while let page = chart.page(at: 0) {
          chart.removePage(at: 0)
          original.insert(page, at: original.pageCount)
        }
        if let combined = original.dataRepresentation() {
          try combined.write(to: output, options: .atomic)
          return output
        }
      }
    }
    try data.write(to: output, options: .atomic)
    return output
  }
}


/// Uses observed changes in unique mastered knowledge, not time-on-task.
/// No historical events are inferred from migrated legacy attempts.
enum KnowledgeDeadlineForecast {
  struct Result {
    let currentKnown: Int
    let requiredKnown: Int
    let remaining: Int
    let observedPerDay: Double?
    let estimatedCompletion: Date?
    let reportLines: [String]
  }

  static func evaluate(goal: LearningGoal, knowledgeIDs: Set<UUID>,
                       states: [UUID: LearningState],
                       history: [LearningRepository.KnowledgeProgressEvent],
                       now: Date = .now, calendar: Calendar = .current) -> Result {
    let total = knowledgeIDs.count
    let target = min(total, max(0, Int(ceil(Double(total) * Double(goal.masteryTarget) / 100.0))))
    let known = knowledgeIDs.filter { states[$0]?.masteryLevel == .known }.count
    let remaining = max(0, target - known)
    let title = "Цель «\(goal.title)»: освоено \(known)/\(total), требуется \(target) (\(goal.masteryTarget)%)."
    if remaining == 0 {
      return .init(currentKnown: known, requiredKnown: target, remaining: 0,
                   observedPerDay: nil, estimatedCompletion: now,
                   reportLines: [title, "Цель по освоению достигнута."])
    }
    // A rolling 28-day window avoids treating old bursts as the current pace.
    // Require activity on at least three separate calendar days before forecasting.
    let windowStart = calendar.date(byAdding: .day, value: -27, to: calendar.startOfDay(for: now))!
    let relevant = history.filter { knowledgeIDs.contains($0.knowledgeID) && $0.occurredAt <= now }
      .sorted { $0.occurredAt < $1.occurredAt }
    let recent = relevant.filter { $0.occurredAt >= windowStart }
    let observationDays = Set(recent.map { calendar.startOfDay(for: $0.occurredAt) })
    guard observationDays.count >= 3, let first = recent.first, let last = recent.last else {
      return .init(currentKnown: known, requiredKnown: target, remaining: remaining,
                   observedPerDay: nil, estimatedCompletion: nil,
                   reportLines: [title, "Недостаточно истории освоения для прогноза (нужны занятия минимум в 3 разных дня за последние 28 дней)."])
    }
    // Snapshot at window start, including states last observed before the window.
    var baseline: [UUID: Bool] = [:]
    for event in relevant where event.occurredAt < windowStart { baseline[event.knowledgeID] = event.isKnown }
    var latest = baseline
    for event in recent { latest[event.knowledgeID] = event.isKnown }
    let gained = latest.values.filter { $0 }.count - baseline.values.filter { $0 }.count
    let elapsed = max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: first.occurredAt),
                          to: calendar.startOfDay(for: last.occurredAt)).day ?? 1)
    let rate = Double(gained) / Double(elapsed)
    guard rate > 0 else {
      return .init(currentKnown: known, requiredKnown: target, remaining: remaining,
                   observedPerDay: rate, estimatedCompletion: nil,
                   reportLines: [title, "Устойчивого прироста освоенных знаний пока нет. Рекомендуется чаще повторять сложные темы и проверить динамику через несколько дней."])
    }
    let neededDays = Int(ceil(Double(remaining) / rate))
    guard neededDays < 36500, let predicted = calendar.date(byAdding: .day, value: neededDays, to: now) else {
      return .init(currentKnown: known, requiredKnown: target, remaining: remaining,
                   observedPerDay: rate, estimatedCompletion: nil,
                   reportLines: [title, "Прогноз слишком далёкий; необходимо пересмотреть темп занятий."])
    }
    var lines = [title,
      "Наблюдаемый прирост: \(String(format: "%.2f", rate)) знания/день; прогноз достижения: \(predicted.formatted(date: .abbreviated, time: .omitted))."]
    if let deadline = goal.deadline {
      let daysLeft = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                             to: calendar.startOfDay(for: deadline)).day ?? 0
      let lead = calendar.dateComponents([.day], from: calendar.startOfDay(for: predicted),
                                         to: calendar.startOfDay(for: deadline)).day ?? 0
      if lead >= 0 {
        lines.append("Прогноз: опережение срока на \(lead) дн. Сохраняйте устойчивый темп.")
      } else {
        let neededRate = Double(remaining) / Double(max(1, daysLeft))
        let multiplier = neededRate / rate
        lines.append("Прогноз: отставание от срока на \(abs(lead)) дн. Для цели требуется около \(String(format: "%.2f", neededRate)) знания/день (\(String(format: "%.1f", multiplier))× текущего темпа).")
        lines.append("Рекомендация: увеличить частоту или длительность занятий постепенно, сохраняя повторения; оценить эффект через неделю.")
      }
    }
    lines.append("Прогноз ориентировочный: окно последних 28 дней; основан на приросте устойчивых знаний, не гарантирует результат.")
    return .init(currentKnown: known, requiredKnown: target, remaining: remaining,
                 observedPerDay: rate, estimatedCompletion: predicted, reportLines: lines)
  }
}

/// Home-only semantic palette; the learning game's dark HomeTheme is unchanged.
private enum HomePalette {
  static let accent = Color(red: 0.18, green: 0.43, blue: 0.79)
  static let success = Color(red: 0.12, green: 0.55, blue: 0.36)
  static let warning = Color(red: 0.65, green: 0.37, blue: 0.05)
}
private struct LightHomeMetric: View {
  let value: String
  let label: String
  var body: some View {
    VStack(spacing: 4) {
      Text(value).font(.headline.bold()).foregroundStyle(.primary)
      Text(label).font(.caption2.weight(.semibold)).foregroundStyle(HomePalette.accent)
        .minimumScaleFactor(0.8).lineLimit(2)
    }.frame(maxWidth: .infinity, minHeight: 58)
      .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
  }
}
private extension View {
  func lightHomeCard() -> some View {
    background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
      .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(0.07)))
  }
}

/// Scope is chosen when starting a session; it is independent of goal time allocation.
private struct SessionLaunchPicker: View {
  let courses: [StudyCourse]
  let materials: MaterialStore
  let learning: LearningStore
  let start: ([StudyQuestion], String) -> Void
  @Environment(\.dismiss) private var dismiss
  private func questions(_ refs: [CourseRuleReference]) -> [StudyQuestion] {
    refs.flatMap { ref -> [StudyQuestion] in
      guard let content = materials.content(id: ref.materialID) else { return [] }
      return StudyQuestionBuilder.questions(for: ref, content: content)
    }
  }
  private var allRefs: [CourseRuleReference] {
    courses.flatMap { $0.sections.flatMap { $0.topics.flatMap(\.questionSets) } }
  }
  var body: some View {
    NavigationStack {
      List {
        Section("Быстрый старт") {
          launchRow("Все предметы вперемешку", refs: allRefs)
          launchRow("Повторить изученное", refs: allRefs, dueOnly: true)
        }
        ForEach(courses) { course in
          Section(course.title) {
            launchRow("Весь предмет · \(course.subject.isEmpty ? course.title : course.subject)",
              refs: course.sections.flatMap { $0.topics.flatMap(\.questionSets) })
            ForEach(course.sections) { section in
              ForEach(section.topics) { topic in
                launchRow(topic.title, refs: topic.questionSets)
              }
            }
          }
        }
      }.navigationTitle("Что будем учить?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Закрыть") { dismiss() } }
    }
  }
  private func launchRow(_ title: String, refs: [CourseRuleReference], dueOnly: Bool = false) -> some View {
    let candidates = questions(refs)
    let selected = dueOnly ? candidates.filter {
      guard let state = learning.knowledgeStates[$0.knowledgeID] else { return false }
      return state.nextDueAt <= .now
    } : candidates
    return Button {
      start(selected, title)
    } label: {
      HStack {
        Text(title)
        Spacer()
        Text("\(selected.count)").foregroundStyle(.secondary).font(.caption)
      }
    }.disabled(selected.isEmpty)
  }
}
