import SwiftUI

struct ProgressDashboardView: View {
    enum Period: String, CaseIterable, Identifiable {
        case week = "Неделя", month = "Месяц", quarter = "3 месяца", all = "Всё"
        var id: Self { self }
    }

    @State private var period: Period = .week

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
                            Text("126 вопросов").font(.title2.bold())
                            Text("5 учебных дней · 84% точность · 2 ч 18 мин")
                            Text("Сравнение с предыдущим периодом появится после накопления истории.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    GroupBox("Серия и рекорды") {
                        Label("12 дней подряд", systemImage: "flame.fill")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Прогресс")
        }
    }
}
