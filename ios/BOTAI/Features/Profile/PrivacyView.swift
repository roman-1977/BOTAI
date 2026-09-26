import SwiftUI
struct PrivacyView: View {
 @Environment(AuthStore.self) private var auth; @State private var confirm=false; @State private var message:String?
 var body: some View { List { Section("Данные") { Text("BOTAI хранит учебный прогресс локально и синхронизирует аккаунтные данные через Supabase."); Button("Запросить удаление аккаунта и данных",role:.destructive){confirm=true} }; if let message { Section { Text(message) } } }.navigationTitle("Приватность").confirmationDialog("Удалить аккаунт и персональные данные?",isPresented:$confirm,titleVisibility:.visible){Button("Запросить удаление",role:.destructive){Task{do{try await AccountSafetyService().requestDeletion(); message="Запрос принят"}catch{message=error.localizedDescription}}};Button("Отмена",role:.cancel){}} }
}
