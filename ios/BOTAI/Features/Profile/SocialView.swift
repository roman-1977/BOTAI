import SwiftUI
struct SocialView: View {
 @State private var friendID=""; @State private var message:String?; @State private var friends:[Friendship]=[]
 var body: some View { List { Section("Добавить друга") { TextField("UUID пользователя",text:$friendID).textInputAutocapitalization(.never); Button("Отправить запрос") { guard let id=UUID(uuidString:friendID) else { message="Неверный ID"; return }; Task { do { try await SocialService().requestFriend(id); message="Запрос отправлен"; await load() } catch { message=error.localizedDescription } } }; if let message { Text(message).font(.caption) } }; Section("Связи") { ForEach(friends) { f in Label(f.status,systemImage:"person.2") } } }.navigationTitle("Друзья").task{await load()} }
 @MainActor private func load() async { friends=(try? await SocialService().friendships()) ?? [] }
}
