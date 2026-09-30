import SwiftUI

struct LearnSessionView: View {
  @Environment(LearningStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @State private var index = 0
  @State private var revealed = false
  @State private var advancing = false
  @State private var checked = false
  @State private var selection: Set<Int> = []
  @State private var finished = false
  @State private var answeredToday = 0
  @State private var studySecondsToday = 0
  @State private var activeStartedAt: Date? = Date()
  @State private var activeQuestionSeconds: TimeInterval = 0
  @State private var showModes = false
  @State private var questionMode = 0
  @State private var answerMode = 0
  @State private var paceMode = 0
  @State private var speedSeconds = 20
  @State private var correctToday = 0
  @State private var sessionID = UUID()
  @State private var sessionStartedAt = Date()
  @State private var sessionAnswered = 0
  @State private var sessionCorrect = 0
  @State private var sessionActiveSeconds = 0
  @State private var wrongToday = 0
  @State private var seenToday: Set<UUID> = []
  var body: some View {
    ZStack {
      LearnDigitalBackground()
      NavigationStack { if finished { resultView } else { questionView } }.background(.clear)
    }.preferredColorScheme(.dark).overlay { if showModes { modeOverlay } }.onChange(of: scenePhase)
    { _, phase in handleScenePhase(phase) }
  }
  private var question: StudyQuestion { store.questions[index] }
  // Layout invariant: reserve the maximum two-line topic header and six-answer area first.
  // The card receives every remaining point so its height never changes between question types.
  private var questionView: some View {
    GeometryReader { geo in
      let fixedTop: CGFloat = 68 + 42 + 28
      let fixedBottom: CGFloat = 356 + 54 + 28
      let cardH = max(220, geo.size.height - fixedTop - fixedBottom)
      VStack(spacing: 10) {
        sessionHeader
        topicBadge.padding(.horizontal, 18).padding(.top, 8).frame(height: 50, alignment: .top)
        questionCard.frame(height: cardH)
        answerArea.frame(height: 356, alignment: .top)
        Button {
          dismiss()
        } label: {
          HStack {
            Image(systemName: "pause.fill")
            Text("ПРИОСТАНОВИТЬ ЗАНЯТИЕ").font(.headline)
          }.foregroundStyle(.white.opacity(0.9)).frame(maxWidth: .infinity).frame(height: 54)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18)).overlay(
              RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.15)))
        }.buttonStyle(.plain).padding(.horizontal, 18).padding(.bottom, 8)
      }.toolbar(.hidden, for: .navigationBar)
    }
  }
  private var sessionHeader: some View {
    HStack(spacing: 0) {
      HStack(spacing: 0) {
        GoalRing(value: answeredToday, target: max(1, store.questions.count), label: "ВОПРОСЫ", tint: .mint)
        Spacer(minLength: 0)
        GoalRing(value: studySecondsToday / 60, target: max(1, store.sessionTargetMinutes), label: "МИНУТЫ", tint: .cyan)
        Spacer(minLength: 0)
        AnswerSplitRing(correct: correctToday, wrong: wrongToday)
        Spacer(minLength: 0)
        CoverageRing(seen: seenToday.count, total: store.questions.count)
      }.frame(maxWidth: .infinity)
      Spacer().frame(width: 10)
      Button {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showModes = true }
      } label: {
        ZStack {
          RoundedRectangle(cornerRadius: 13).fill(.cyan.opacity(0.07))
          RoundedRectangle(cornerRadius: 13).stroke(.cyan.opacity(0.55), lineWidth: 1.3)
          VStack(spacing: 5) {
            Image(systemName: "slider.vertical.3").font(.headline)
            Text("РЕЖИМ").font(.system(size: 6, weight: .bold)).tracking(0.5)
          }.foregroundStyle(.cyan).shadow(color: .cyan.opacity(0.7), radius: 4)
        }.frame(width: 34, height: 68)
      }
    }.padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 8)
  }
  private let modes = [("УЧИМ", "book.fill"), ("ПОВТОРЯЕМ", "arrow.clockwise"), ("AI", "sparkles")]
  private let answerModes = [
    ("КАРТОЧКА", "rectangle.portrait"), ("ТЕСТ", "list.bullet.rectangle"), ("AI", "sparkles"),
  ]
  private var modeOverlay: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.48).ignoresSafeArea().onTapGesture { showModes = false }
      VStack(spacing: 18) {
        Capsule().fill(.white.opacity(0.18)).frame(width: 42, height: 4)
        modeRow(title: "СТРАТЕГИЯ", items: modes, selection: questionMode) { questionMode = $0 }
        modeRow(title: "ФОРМАТ", items: answerModes, selection: answerMode) { answerMode = $0 }
        paceRow
        Button {
          withAnimation { showModes = false }
        } label: {
          Text("ГОТОВО").font(.caption.bold()).tracking(1.5).foregroundStyle(.cyan).frame(
            maxWidth: .infinity
          ).frame(height: 42).background(
            .cyan.opacity(0.09), in: RoundedRectangle(cornerRadius: 14)
          ).overlay(RoundedRectangle(cornerRadius: 14).stroke(.cyan.opacity(0.3)))
        }
      }.padding(18).padding(.bottom, 12).background(
        .ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30)
      ).overlay(
        UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30).stroke(
          LinearGradient(
            colors: [.cyan.opacity(0.45), .purple.opacity(0.2)], startPoint: .topLeading,
            endPoint: .topTrailing), lineWidth: 1)
      ).shadow(color: .cyan.opacity(0.12), radius: 24)
    }
  }
  private var paceRow: some View {
    VStack(spacing: 10) {
      Text("ТЕМП").frame(maxWidth: .infinity, alignment: .center).font(.caption2.bold()).tracking(
        1.7
      ).foregroundStyle(.white.opacity(0.5))
      HStack(spacing: 10) {
        modeTile("СПОКОЙНО", "leaf.fill", selected: paceMode == 0) { paceMode = 0 }
        modeTile(
          paceMode == 1 ? "\(speedSeconds) СЕК" : "НА СКОРОСТЬ", "timer", selected: paceMode == 1
        ) {
          if paceMode == 1 {
            let values = [10, 20, 30, 60]
            speedSeconds =
              values[
                (values.firstIndex(of: speedSeconds) ?? 0) + 1 < values.count
                  ? (values.firstIndex(of: speedSeconds) ?? 0) + 1 : 0]
          } else {
            paceMode = 1
          }
        }
        modeTile("AI", "sparkles", selected: paceMode == 2) { paceMode = 2 }
      }
    }
  }
  private func modeTile(
    _ title: String, _ icon: String, selected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 8) {
        ZStack {
          Hexagon().fill(selected ? Color.cyan.opacity(0.18) : Color.white.opacity(0.045))
          Hexagon().stroke(
            selected ? Color.cyan : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
          Image(systemName: icon).font(.title2).foregroundStyle(
            selected ? .cyan : .white.opacity(0.72)
          ).shadow(color: selected ? .cyan : .clear, radius: 7)
        }.frame(height: 62)
        Text(title).font(.system(size: 10, weight: .bold)).foregroundStyle(
          selected ? .cyan : .white.opacity(0.68))
      }.frame(maxWidth: .infinity)
    }.buttonStyle(.plain)
  }
  private func modeRow(
    title: String, items: [(String, String)], selection: Int, onSelect: @escaping (Int) -> Void
  ) -> some View {
    VStack(spacing: 10) {
      Text(title).frame(maxWidth: .infinity, alignment: .center).font(.caption2.bold()).tracking(
        1.7
      ).foregroundStyle(.white.opacity(0.5))
      HStack(spacing: 10) {
        ForEach(Array(items.enumerated()), id: \.offset) { i, m in
          Button {
            onSelect(i)
          } label: {
            VStack(spacing: 8) {
              ZStack {
                Hexagon().fill(
                  i == selection ? Color.cyan.opacity(0.18) : Color.white.opacity(0.045))
                Hexagon().stroke(
                  i == selection ? Color.cyan : Color.white.opacity(0.12),
                  lineWidth: i == selection ? 2 : 1)
                Image(systemName: m.1).font(.title2).foregroundStyle(
                  i == selection ? .cyan : .white.opacity(0.72)
                ).shadow(color: i == selection ? .cyan : .clear, radius: 7)
              }.frame(height: 62)
              Text(m.0).font(.system(size: 10, weight: .bold)).foregroundStyle(
                i == selection ? .cyan : .white.opacity(0.68))
            }.frame(maxWidth: .infinity)
          }
        }.buttonStyle(.plain)
      }
    }
  }
  private var topicBadge: some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: "atom").frame(width: 18).padding(.top, 2)
      Text(store.sessionTitle.uppercased()).font(.subheadline.bold()).tracking(0.2).lineLimit(
        2
      ).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.leading)
        .layoutPriority(1)
      Spacer(minLength: 0)
    }.foregroundStyle(.cyan).frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)
  }
  private var questionCard: some View {
    VStack(spacing: 14) {
      ZStack {
        Circle().fill(.cyan.opacity(0.08)).frame(width: 66, height: 66)
        Image(systemName: revealed ? "checkmark.seal.fill" : "flask.fill").font(.title)
          .foregroundStyle(revealed ? .mint : .cyan).shadow(color: .cyan.opacity(0.7), radius: 9)
      }
      Text(revealed ? question.answer : question.prompt).font(
        .system(size: 27, weight: .bold, design: .rounded)
      ).foregroundStyle(.white).multilineTextAlignment(.center).minimumScaleFactor(0.75)
      Text(revealed ? "Нажми оценку ниже" : "Нажми на карточку, чтобы перевернуть").font(.caption)
        .foregroundStyle(.white.opacity(0.48))
    }.padding(.horizontal, 18).padding(.vertical, 22).frame(
      maxWidth: .infinity, maxHeight: .infinity
    ).background(.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 28)).overlay(
      RoundedRectangle(cornerRadius: 28).stroke(
        LinearGradient(
          colors: [.cyan.opacity(0.45), .purple.opacity(0.22)], startPoint: .topLeading,
          endPoint: .bottomTrailing), lineWidth: 1)
    ).rotation3DEffect(.degrees(advancing ? 180 : (revealed ? 360 : 0)), axis: (x: 0, y: 1, z: 0))
      .animation(.spring(response: 0.5, dampingFraction: 0.78), value: revealed).onTapGesture {
        if question.kind == .reveal {
          revealed.toggle()
        } else if (question.kind == .singleChoice || question.kind == .multipleChoice) && checked {
          animateAdvanceAfterChoice()
        } else if question.kind == .multipleChoice && checked {
          animateAdvanceAfterChoice()
        } else if checked {
          revealed.toggle()
        }
      }
  }
  // After a test is checked, the whole answer region advances the session, not just a choice button.
  @ViewBuilder private var answerArea: some View {
    if question.kind == .reveal || question.kind == .pair {
      revealAnswer
    } else {
      choiceAnswer.contentShape(Rectangle()).onTapGesture {
        if checked { animateAdvanceAfterChoice() }
      }
    }
  }
  private var revealAnswer: some View {
    Group {
      if revealed {
        VStack(spacing: 8) {
          confidenceButton("ОТВЕТИЛ ЛЕГКО", .good, .mint)
          confidenceButton("СОМНЕВАЛСЯ", .hard, .yellow)
          confidenceButton("ПОВЕЗЛО — УГАДАЛ", .hard, .orange)
          confidenceButton("НАДО ПОВТОРЯТЬ", .again, .pink)
        }
      } else {
        Color.clear
      }
    }.frame(maxHeight: .infinity, alignment: .top)
  }
  private func confidenceButton(_ title: String, _ value: RecallRating, _ color: Color) -> some View
  {
    Button {
      submit(value)
    } label: {
      HStack {
        Circle().fill(color).frame(width: 8, height: 8)
        Text(title).font(.subheadline.bold())
        Spacer()
        Image(systemName: "chevron.right")
      }.foregroundStyle(.white).padding(.horizontal, 16).frame(height: 46).background(
        color.opacity(0.10), in: RoundedRectangle(cornerRadius: 15)
      ).overlay(RoundedRectangle(cornerRadius: 15).stroke(color.opacity(0.35)))
    }.buttonStyle(.plain)
  }
  private var choiceAnswer: some View {
    VStack(spacing: 10) {
      ForEach(Array(question.choices.prefix(6).enumerated()), id: \.offset) { i, c in
        Button {
          if (question.kind == .singleChoice || question.kind == .multipleChoice) && checked {
            animateAdvanceAfterChoice()
          } else {
            choose(i)
          }
        } label: {
          HStack(spacing: 12) {
            Text(["A", "B", "C", "D"][min(i, 3)]).font(.caption.bold()).frame(width: 30, height: 30)
              .background(choiceColor(i).opacity(0.18), in: Circle())
            Text(c).font(.body.weight(.semibold))
            Spacer()
            if checked && question.correctChoiceIndexes.contains(i) {
              Image(systemName: "checkmark.circle.fill")
            }
          }.foregroundStyle(choiceColor(i)).padding(.horizontal, 14).frame(height: 52).background(
            choiceColor(i).opacity(0.07), in: RoundedRectangle(cornerRadius: 18)
          ).overlay(RoundedRectangle(cornerRadius: 18).stroke(choiceColor(i).opacity(0.38)))
        }.buttonStyle(.plain)
      }
      if question.kind == .multipleChoice && !checked {
        Button {
          checkAnswers()
        } label: {
          Text("ОТВЕТИТЬ").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).frame(
            height: 54
          ).background(
            selection.isEmpty ? Color.white.opacity(0.08) : Color.blue.opacity(0.8),
            in: RoundedRectangle(cornerRadius: 18))
        }.disabled(selection.isEmpty)
      }
      if checked {
        Text(
          question.kind == .singleChoice
            ? "Правильный ответ подсвечен · нажми ещё раз, чтобы дальше"
            : "Правильные ответы подсвечены · нажми ещё раз, чтобы дальше"
        ).font(.caption).foregroundStyle(.mint)
        if revealed && question.kind != .singleChoice && question.kind != .multipleChoice {
          ratingButtons
        }
      }
    }
  }
  private func choiceColor(_ i: Int) -> Color {
    if checked {
      return question.correctChoiceIndexes.contains(i)
        ? .mint : (selection.contains(i) ? .orange : .white)
    }
    return selection.contains(i) ? .cyan : .white
  }
  private func choose(_ i: Int) {
    if question.kind == .singleChoice {
      selection = [i]
      checkAnswers()
    } else if selection.contains(i) {
      selection.remove(i)
    } else {
      selection.insert(i)
    }
  }
  private func animateAdvanceAfterChoice() {
    guard !advancing else { return }
    withAnimation(.easeIn(duration: 0.22)) { advancing = true }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
      advanceAfterChoice()
      withAnimation(.easeOut(duration: 0.22)) { advancing = false }
    }
  }
  private func advanceAfterChoice() {
    countQuestionTime()
    answeredToday += 1
    let ok = selection == question.correctChoiceIndexes
    if ok { correctToday += 1 } else { wrongToday += 1 }
    store.record(question: question, rating: ok ? .good : .again)
    if index + 1 < store.questions.count {
      index += 1
      activeStartedAt = scenePhase == .active ? Date() : nil
      activeQuestionSeconds = 0
      revealed = false
      checked = false
      selection = []
    } else {
      finished = true
    }
  }
  private func checkAnswers() { withAnimation(.easeInOut(duration: 0.2)) { checked = true } }
  private var ratingButtons: some View {
    HStack(spacing: 8) {
      rating("НЕ ПОМНЮ", .again, .orange)
      rating("С ТРУДОМ", .hard, .yellow)
      rating("ЗНАЮ", .good, .mint)
    }
  }
  private func rating(_ title: String, _ value: RecallRating, _ color: Color) -> some View {
    Button {
      submit(value)
    } label: {
      Text(title).font(.system(size: 11, weight: .bold)).foregroundStyle(color).frame(
        maxWidth: .infinity
      ).frame(height: 44).background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.35)))
    }.buttonStyle(.plain)
  }
  private var resultView: some View {
    VStack(spacing: 20) {
      Spacer()
      ZStack {
        Circle().fill(.cyan.opacity(0.12)).frame(width: 150, height: 150)
        Image(systemName: "sparkles").font(.system(size: 66)).foregroundStyle(.cyan).shadow(
          color: .cyan, radius: 18)
      }
      Text("ВОПРОСЫ ЗАКОНЧИЛИСЬ").font(.largeTitle.bold()).foregroundStyle(.white)
      Text("Сегодня: \(answeredToday) вопросов · \(studySecondsToday/60) мин").font(.title3.bold())
        .foregroundStyle(.cyan)
      Button("ГОТОВО") { dismiss() }.buttonStyle(.borderedProminent).controlSize(.large)
      Spacer()
    }.padding()
  }
  private func toggle(_ i: Int) {
    if question.kind == .singleChoice {
      selection = [i]
    } else if selection.contains(i) {
      selection.remove(i)
    } else {
      selection.insert(i)
    }
  }
  private func submit(_ r: RecallRating) {
    countQuestionTime()
    answeredToday += 1
    sessionAnswered += 1
    if r == .good { correctToday += 1; sessionCorrect += 1 } else { wrongToday += 1 }
    persistSession()
    store.record(question: question, rating: r)
    if r == .good {
    } else if r == .hard {
    } else {
    }
    if index + 1 < store.questions.count {
      index += 1
      activeStartedAt = scenePhase == .active ? Date() : nil
      activeQuestionSeconds = 0
      revealed = false
      checked = false
      selection = []
    } else {
      finished = true
    }
  }
  // Study time counts only while the app is active and is committed when the question is completed.
  private func countQuestionTime() {
    seenToday.insert(question.id)
    var total = activeQuestionSeconds
    if let start = activeStartedAt { total += Date().timeIntervalSince(start) }
    let seconds=max(0,Int(total));studySecondsToday += seconds;sessionActiveSeconds += seconds
    activeStartedAt = nil
    activeQuestionSeconds = 0
  }

  private func persistSession() { store.saveSession(.init(id:sessionID,startedAt:sessionStartedAt,endedAt:.now,activeSeconds:sessionActiveSeconds,answered:sessionAnswered,correct:sessionCorrect)) }
  private func handleScenePhase(_ phase: ScenePhase) {
    switch phase {
    case .active: if activeStartedAt == nil { activeStartedAt = Date() }
    case .inactive, .background:
      if let start = activeStartedAt {
        activeQuestionSeconds += Date().timeIntervalSince(start)
        activeStartedAt = nil
      }
    @unknown default: break
    }
  }

}
private struct LearnDigitalBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.015, green: 0.025, blue: 0.08), Color(red: 0.025, green: 0.055, blue: 0.14),
          Color(red: 0.08, green: 0.025, blue: 0.16),
        ], startPoint: .topLeading, endPoint: .bottomTrailing
      ).ignoresSafeArea()
      Circle().fill(.cyan.opacity(0.10)).frame(width: 280, height: 280).blur(radius: 70).offset(
        x: -150, y: -270)
      Circle().fill(.purple.opacity(0.12)).frame(width: 300, height: 300).blur(radius: 80).offset(
        x: 160, y: 250)
    }
  }
}
private struct GoalRing: View {
  let value: Int
  let target: Int
  let label: String
  let tint: Color
  var body: some View {
    let ratio = CGFloat(value) / CGFloat(max(target, 1))
    ZStack {
      Circle().stroke(.white.opacity(0.08), lineWidth: 8)
      Circle().trim(from: 0, to: min(ratio, 1)).stroke(
        tint, style: StrokeStyle(lineWidth: 8, lineCap: .round)
      ).rotationEffect(.degrees(-90)).shadow(color: tint.opacity(0.5), radius: 5)
      if ratio > 1 {
        Circle().trim(from: 0, to: min(ratio - 1, 1)).stroke(
          tint.opacity(0.45), style: StrokeStyle(lineWidth: 4, lineCap: .round)
        ).rotationEffect(.degrees(-90)).padding(7)
      }
      VStack(spacing: 0) {
        Text("\(value)").font(.title3.bold().monospacedDigit())
        Text("/\(target)").font(.caption2.bold()).foregroundStyle(.white.opacity(0.55))
      }
    }.frame(width: 68, height: 68).overlay(alignment: .bottom) {
      Text(label).font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.72))
        .offset(y: 16)
    }
  }
}
private struct AnswerSplitRing: View {
  let correct: Int
  let wrong: Int
  var body: some View {
    let total = max(correct + wrong, 1)
    let good = CGFloat(correct) / CGFloat(total)
    ZStack {
      Circle().stroke(.white.opacity(0.08), lineWidth: 8)
      Circle().trim(from: 0, to: good).stroke(
        .green, style: StrokeStyle(lineWidth: 8, lineCap: .butt)
      ).rotationEffect(.degrees(-90))
      Circle().trim(from: good, to: 1).stroke(
        .red, style: StrokeStyle(lineWidth: 8, lineCap: .butt)
      ).rotationEffect(.degrees(-90))
      VStack(spacing: 1) {
        HStack(spacing: 4) {
          Text("\(correct)").foregroundStyle(.green)
          Text("/")
          Text("\(wrong)").foregroundStyle(.red)
        }.font(.headline.bold().monospacedDigit())
      }
    }.frame(width: 68, height: 68).overlay(alignment: .bottom) {
      Text("ОТВЕТЫ").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.72))
        .offset(y: 16)
    }
  }
}
private struct CoverageRing: View {
  let seen: Int
  let total: Int
  var body: some View {
    let ratio = min(CGFloat(seen) / CGFloat(max(total, 1)), 1)
    ZStack {
      Circle().stroke(.white.opacity(0.08), lineWidth: 8)
      Circle().trim(from: 0, to: ratio).stroke(
        .purple, style: StrokeStyle(lineWidth: 8, lineCap: .round)
      ).rotationEffect(.degrees(-90)).shadow(color: .purple.opacity(0.45), radius: 5)
      Text("\(Int(ratio*100))%").font(.headline.bold().monospacedDigit())
    }.frame(width: 68, height: 68).overlay(alignment: .bottom) {
      Text("ОХВАТ").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.72))
        .offset(y: 16)
    }
  }
}
private struct Hexagon: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let pts = [
      CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
      CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75), CGPoint(x: rect.midX, y: rect.maxY),
      CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75),
      CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25),
    ]
    p.move(to: pts[0])
    for x in pts.dropFirst() { p.addLine(to: x) }
    p.closeSubpath()
    return p
  }
}
