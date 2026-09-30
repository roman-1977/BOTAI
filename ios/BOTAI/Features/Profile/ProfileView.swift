import AuthenticationServices
import SwiftUI

struct ProfileView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(StudyProfileStore.self) private var studyProfile
    var body: some View {
        NavigationStack {
            List {
                Section("Обучение") { NavigationLink { StudyScheduleView() } label: { HStack { Label("Режим обучения", systemImage: "timer"); Spacer(); Text("\(studyProfile.profile.defaultDailyMinutes) мин/день").foregroundStyle(.secondary) } }; NavigationLink { GoalsView() } label: { Label("Цели", systemImage: "target") } }
                Section("Аккаунт") {
                    if auth.isAuthenticated {
                        Label("Аккаунт подключён", systemImage: "checkmark.seal.fill")
                        Button("Выйти", role: .destructive) { Task { await auth.signOut() } }
                    } else {
                        #if DEBUG
                        Button("Войти для тестирования") { Task { await auth.signInForDevelopment() } }.buttonStyle(.borderedProminent)
                        #endif
                        SignInWithAppleButton(.signIn) { request in request.requestedScopes = [.fullName, .email] } onCompletion: { result in
                            guard case let .success(authorization) = result, let credential = authorization.credential as? ASAuthorizationAppleIDCredential, let data = credential.identityToken, let token = String(data: data, encoding: .utf8) else { return }
                            Task { await auth.signInWithApple(idToken: token) }
                        }.signInWithAppleButtonStyle(.black).frame(height: 48)
                        if let message = auth.errorMessage { Text(message).font(.caption).foregroundStyle(.red) }
                    }
                    NavigationLink { SocialView() } label: { Label("Друзья", systemImage: "person.2") }; NavigationLink { PrivacyView() } label: { Label("Приватность", systemImage: "hand.raised") }; Label("Настройки", systemImage: "gearshape")
                }
            }.navigationTitle("Профиль")
        }
    }
}
