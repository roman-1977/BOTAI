import SwiftUI
import UIKit

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
  @State private var reportURL: URL?
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
            reportAction
            launch
          }.padding(.horizontal, 14).padding(.bottom, 26)
        }
      }.toolbar(.hidden, for: .navigationBar).confirmationDialog(
        "Что изучать?", isPresented: $chooseGoal, titleVisibility: .visible
      ) {
        ForEach(plan.goals) { g in Button("\(g.title) · \(g.questions.count) вопросов") { start(g) }
        }
        Button("Отмена", role: .cancel) {}
      }.sheet(isPresented: Binding(get: { reportURL != nil }, set: { if !$0 { reportURL = nil } })) {
        if let url = reportURL { PDFShareSheet(url: url) }
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
    }.padding(16).homeCard()
  }
  private var todayDetails: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("ПЛАН НА СЕГОДНЯ").font(.caption.bold()).foregroundStyle(HomeTheme.accent)
      Text(
        plan.budgetMinutes == 0
          ? "По плану отдых · заниматься можно" : "\(plan.budgetMinutes) минут на обучение"
      ).font(.title2.bold()).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
      Text(
        plan.goals.isEmpty ? emptyPlanText : "BOTAI распределил время между текущими целями."
      ).font(.caption).foregroundStyle(HomeTheme.muted)
    }
  }
  private var todayProgressRing: some View {
    ZStack {
      Circle().stroke(.white.opacity(0.1), lineWidth: 8)
      Circle().trim(
        from: 0, to: min(1, Double(todayMinutes) / Double(max(1, plan.budgetMinutes)))
      ).stroke(HomeTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Text("\(todayMinutes)").font(.headline.bold()).foregroundStyle(.white)
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
    }.padding(12).homeCard()
  }
  @ViewBuilder
  private var progressMetrics: some View {
    HomeMetric(value: "\(learning.masteryPercent)%", label: "ОСВОЕНО")
    HomeMetric(value: "\(learning.dueCount)", label: "ПОВТОРИТЬ")
    HomeMetric(value: timeText(learning.analytics.totalSeconds), label: "ВСЕГО")
  }
  private var reportAction: some View {
    Button {
      do {
        reportURL = try StudyPDFReport.export(profile: profile.profile, sessions: learning.sessions,
          attempts: learning.attempts, knowledgeStates: learning.knowledgeStates,
          courses: courses.courses, materials: materials, knowledgeHistory: learning.knowledgeHistory)
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
        startPlan()
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "play.fill").font(.title2).foregroundStyle(.white).frame(
            width: 52, height: 52
          ).background(.white.opacity(0.16), in: Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text("УЧИТЬСЯ СЕГОДНЯ").font(.headline).lineLimit(2)
            Text(launchSubtitle).font(.caption).opacity(0.72).lineLimit(3)
          }
          Spacer()
          Image(systemName: "chevron.right")
        }.foregroundStyle(.white).padding(.horizontal, 14).frame(minHeight: 78).padding(.vertical, 6).background(
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
      let planned = profile.minutes(for: calendar.component(.weekday, from: day))
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
    let activeDeadlines = courses.flatMap(\.goals).filter { $0.state == .active && $0.deadline != nil }
    if !activeDeadlines.isEmpty {
      lines.append("Прогноз достижения учебных целей: пока недостаточно истории изменения освоения.")
      lines.append("Текущий темп минут не равен скорости освоения знаний; прогноз готовности по дедлайну будет добавлен после накопления снимков прогресса.")
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
