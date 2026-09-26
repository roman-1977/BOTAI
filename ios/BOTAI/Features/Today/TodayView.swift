import SwiftUI

struct TodayView: View {
    @Environment(LearningStore.self) private var store
    @State private var showingLearn = false
    private var plan: DailyPlan { DailyPlan(completed: store.completedToday, recommended: 18, habitMinimum: 5, due: 8, weak: 6, new: 4) }

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
                    Text("Темп будет рассчитан по выбранному материалу и сроку.")
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
            Label("Здесь появится сравнение с твоей собственной недавней динамикой.", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline)
        }
    }
}
