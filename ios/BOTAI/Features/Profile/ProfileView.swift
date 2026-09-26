import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Обучение") {
                    Label("Цели", systemImage: "target")
                    Label("Дневной минимум", systemImage: "checkmark.circle")
                }
                Section("Аккаунт") {
                    Label("Приватность", systemImage: "hand.raised")
                    Label("Настройки", systemImage: "gearshape")
                }
            }
            .navigationTitle("Профиль")
        }
    }
}
