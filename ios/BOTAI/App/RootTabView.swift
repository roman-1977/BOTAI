import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Сегодня", systemImage: "house") }
            LibraryView()
                .tabItem { Label("Библиотека", systemImage: "books.vertical") }
            ProgressDashboardView()
                .tabItem { Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis") }
            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
        }
    }
}
