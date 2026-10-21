import SwiftUI

struct ProgressDashboardView: View {
    @Environment(LearningStore.self) private var learning

    private var analytics: LearningAnalytics { learning.analytics }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(.secondary.opacity(0.15), lineWidth: 10)
                            Circle().trim(from: 0, to: CGFloat(learning.masteryPercent) / 100)
                                .stroke(.blue, lineWidth: 10)
                                .rotationEffect(.degrees(-90))
                            Text("\(learning.masteryPercent)%").bold()
                        }
                        .frame(width: 105, height: 105)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Освоение материала").font(.title3.bold())
                            Text("\(analytics.totalAnswered) ответов · \(analytics.totalCorrect) верно")
                            Text("\(learning.streak) дней подряд")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Статистика обучения").font(.title2.bold())
                    LabeledContent("Точность", value: "\(Int((analytics.accuracy * 100).rounded()))%")
                    LabeledContent("Время занятий", value: "\(analytics.totalSeconds / 60) мин")
                    LabeledContent("Завершённых и начатых занятий", value: "\(analytics.sessions.count)")

                    Text("Последние занятия").font(.title2.bold())
                    if analytics.sessions.isEmpty {
                        ContentUnavailableView("Занятий пока нет", systemImage: "chart.bar",
                                               description: Text("Статистика появится после первого занятия."))
                    } else {
                        ForEach(analytics.sessions.sorted { $0.startedAt > $1.startedAt }.prefix(10)) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.startedAt, format: .dateTime.day().month().year())
                                    .font(.headline)
                                Text("\(session.answered) ответов · \(session.correct) верно · \(session.activeSeconds / 60) мин")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Мой путь")
        }
    }
}
