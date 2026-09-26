import SwiftUI

struct TodayView: View {
    @Environment(LearningStore.self) private var store
    @State private var showingLearn = false
    private var plan: DailyPlan { DailyPlan(completed: store.completedToday, recommended: store.dailyRecommended, habitMinimum: 5, due: store.dueCount, weak: store.weakCount, new: store.newCount) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    goalCard
                    streakRow
                    planCard
                    Button(store.completedToday > 0 ? "ПРОДОЛЖИТЬ" : "БОТАТЬ") { showingLearn = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        .accessibilityHint("Начать занятие по сегодняшнему плану")
                    insightCard
                }
                .padding()
            }
            .navigationTitle("Сегодня")
            .sheet(isPresented: $showingLearn) { LearnSessionView() }
        }
    }

    private var goalCard: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Активная цель").font(.caption).foregroundStyle(.secondary)
                    Text("Учусь по плану").font(.headline)
                    Text("Сегодня: \(store.dailyRecommended) вопросов по текущему прогрессу.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "target").font(.title2)
            }
        }
    }

    private var streakRow: some View {
        Label("\(store.streak) дней занятий подряд", systemImage: "flame.fill")
            .font(.headline)
            .accessibilityLabel("Серия занятий: \(store.streak) дней подряд")
    }

    private var planCard: some View {
        GroupBox("План BOTAI на сегодня") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(plan.completed) / \(plan.recommended)").font(.title.bold())
                    Spacer()
                    Text("вопросов").foregroundStyle(.secondary)
                }
                ProgressView(value: plan.progress)
                Label(plan.isHabitMinimumComplete ? "Минимум дня выполнен" : "До минимума дня ещё немного", systemImage: plan.isHabitMinimumComplete ? "checkmark.circle.fill" : "circle")
                    .font(.subheadline)
                Text("\(plan.due) повторить · \(plan.weak) слабых · \(plan.new) новых")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var insightCard: some View {
        GroupBox {
            Label(store.previousWeek == 0 ? "Накопим неделю истории для сравнения." : "Эта неделя: \(store.thisWeek), прошлая: \(store.previousWeek).", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline)
        }
    }
}
