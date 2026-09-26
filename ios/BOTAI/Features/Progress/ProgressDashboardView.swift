import SwiftUI

struct ProgressDashboardView: View {
    enum Period: String, CaseIterable, Identifiable {
        case week = "Неделя", month = "Месяц", quarter = "3 месяца", all = "Всё"
        var id: Self { self }
    }

    @State private var period: Period = .week
    @Environment(LearningStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Период", selection: $period) {
                        ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    GroupBox("Эта неделя") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(store.thisWeek) вопросов").font(.title2.bold())
                            Text("Прошлая неделя: \(store.previousWeek)")
                            Text(store.previousWeek == 0 ? "Накопим историю для сравнения." : "Изменение: \(store.thisWeek - store.previousWeek >= 0 ? "+" : "")\(store.thisWeek-store.previousWeek) вопросов")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GroupBox("Серия и рекорды") {
                        Label("\(store.streak) дней подряд", systemImage: "flame.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Прогресс")
        }
    }
}
