import AuthenticationServices
import CryptoKit
import Security
import SwiftUI

struct ProfileView: View {
    @State private var appleNonce: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(AuthStore.self) private var auth
    @Environment(StudyProfileStore.self) private var studyProfile
    @Environment(CourseStore.self) private var courses
    var body: some View {
        ZStack { ProfileBG(); ScrollView(showsIndicators:false) { VStack(spacing:14) { identity; studyMode; learning; progress; account }.padding(16).padding(.bottom,24) } }
        .navigationTitle("Профиль").navigationBarTitleDisplayMode(.inline).toolbarBackground(.hidden,for:.navigationBar).preferredColorScheme(.dark)
    }
    private var identity: some View { HStack(spacing:14) { ZStack { Circle().fill(HomeTheme.accent.opacity(0.15)); Image(systemName:"person.fill").font(.title).foregroundStyle(HomeTheme.accent) }.frame(width:62,height:62); VStack(alignment:.leading,spacing:4){Text("МОЙ ПРОФИЛЬ").font(.caption.bold()).foregroundStyle(HomeTheme.accent);Text(auth.isAuthenticated ? "Ученик BOTAI" : "Локальный профиль").font(.title3.bold()).foregroundStyle(.white);Text(auth.isAuthenticated ? "Аккаунт подключён" : "Прогресс хранится на этом устройстве").font(.caption).foregroundStyle(.white.opacity(0.55))};Spacer() }.padding(16).profileCard() }
    private var studyMode: some View { NavigationLink { StudyScheduleView() } label: { HStack(spacing:13) { Image(systemName:"timer").font(.title2).foregroundStyle(HomeTheme.accent).frame(width:36); VStack(alignment:.leading,spacing:4){Text("РЕЖИМ ОБУЧЕНИЯ").font(.caption.bold()).foregroundStyle(HomeTheme.accent);Text(studyProfile.profile.customDays.isEmpty ? "\(studyProfile.profile.defaultDailyMinutes) минут в день" : "Расписание по дням").font(.headline).foregroundStyle(.white);Text(scheduleText).font(.caption).foregroundStyle(.white.opacity(0.58))};Spacer();Image(systemName:"chevron.right").foregroundStyle(HomeTheme.accent) }.padding(16).profileCard() }.buttonStyle(.plain) }
    private var learning: some View { VStack(alignment:.leading,spacing:12){Text("МОЁ ОБУЧЕНИЕ").font(.caption.bold()).foregroundStyle(HomeTheme.accent);Group { if dynamicTypeSize.isAccessibilitySize { VStack(spacing:8) { profileMetrics } } else { HStack(spacing:8) { profileMetrics } } };Text("Курсы и цели редактируются в разделе обучения. Здесь — только состояние твоего учебного плана.").font(.caption).foregroundStyle(.white.opacity(0.5))}.padding(16).profileCard() }
    @ViewBuilder private var profileMetrics: some View {
        ProfileMetric(value:"\(courses.courses.count)",label:"КУРСОВ")
        ProfileMetric(value:"\(activeGoals)",label:"АКТИВНЫХ ЦЕЛЕЙ")
        ProfileMetric(value:"\(plannedGoals)",label:"В ПЛАНЕ")
    }
    private var progress: some View { NavigationLink { StudentProgressView() } label:{HStack(spacing:13){Image(systemName:"chart.xyaxis.line").font(.title2).foregroundStyle(.mint).frame(width:36);VStack(alignment:.leading,spacing:4){Text("МОЙ ПРОГРЕСС").font(.caption.bold()).foregroundStyle(.mint);Text("Динамика обучения").font(.headline).foregroundStyle(.white);Text("Активность, освоение и история занятий").font(.caption).foregroundStyle(.white.opacity(0.58))};Spacer();Image(systemName:"chevron.right").foregroundStyle(.mint)}.padding(16).profileCard()}.buttonStyle(.plain) }
    private var account: some View { VStack(alignment:.leading,spacing:5){Text("АККАУНТ И ПРИЛОЖЕНИЕ").font(.caption.bold()).foregroundStyle(.white.opacity(0.45)).padding(.bottom,4);NavigationLink{SocialView()}label:{ProfileRow(icon:"person.2",title:"Друзья")};NavigationLink{PrivacyView()}label:{ProfileRow(icon:"hand.raised",title:"Приватность")};if auth.isAuthenticated { Button(role:.destructive){Task{await auth.signOut()}}label:{ProfileRow(icon:"rectangle.portrait.and.arrow.right",title:"Выйти",destructive:true)} } else {
SignInWithAppleButton(.signIn, onRequest: { request in
    let nonce = AppleLoginNonce.make()
    appleNonce = nonce
    request.requestedScopes = [.email, .fullName]
    request.nonce = AppleLoginNonce.hash(nonce)
}, onCompletion: { result in
    guard case .success(let authorization) = result,
          let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let data = credential.identityToken,
          let token = String(data: data, encoding: .utf8),
          let nonce = appleNonce else {
        auth.setAppleSignInError("Не удалось получить подтверждение Apple ID. Попробуйте ещё раз.")
        appleNonce = nil
        return
    }
    appleNonce = nil
    Task { await auth.signInWithApple(idToken: token, nonce: nonce) }
}).signInWithAppleButtonStyle(.white).frame(height:48).accessibilityIdentifier("profile-apple-sign-in")
if let error = auth.errorMessage { Text(error).font(.caption).foregroundStyle(.red).accessibilityIdentifier("profile-auth-error") }
#if DEBUG
Button{Task{await auth.signInForDevelopment()}}label:{ProfileRow(icon:"person.badge.key",title:"Войти для тестирования")}
#endif
}}.padding(14).profileCard() }
    private var activeGoals:Int { courses.courses.flatMap(\.goals).filter{$0.state == .active}.count }
    private var plannedGoals:Int { courses.courses.flatMap(\.goals).filter{$0.state == .planned}.count }
    private var scheduleText:String { studyProfile.profile.customDays.isEmpty ? "Каждый день · \(studyProfile.profile.weeklyMinutes/60) ч \(studyProfile.profile.weeklyMinutes%60) мин в неделю" : "Настроено по дням · \(studyProfile.profile.weeklyMinutes/60) ч \(studyProfile.profile.weeklyMinutes%60) мин в неделю" }
}
struct ProfileBG: View {
  var body: some View {
    LinearGradient(colors: [HomeTheme.canvasTop, HomeTheme.canvasMiddle, HomeTheme.canvasBottom],
                   startPoint: .top, endPoint: .bottom).ignoresSafeArea()
  }
}
private struct ProfileMetric:View{let value:String;let label:String;var body:some View{VStack(spacing:4){Text(value).font(.title2.bold()).foregroundStyle(.white);Text(label).font(.caption2.bold()).foregroundStyle(HomeTheme.accent).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)}.frame(maxWidth:.infinity,minHeight:62).background(.black.opacity(0.2),in:RoundedRectangle(cornerRadius:13))}}
private struct ProfileRow:View{let icon:String;let title:String;var destructive=false;var body:some View{HStack{Image(systemName:icon).frame(width:28);Text(title);Spacer();if !destructive{Image(systemName:"chevron.right").font(.caption).opacity(0.45)}}.foregroundStyle(destructive ? .red:.white).padding(.vertical,9)}}
extension View{func profileCard()->some View{background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:20)).overlay(RoundedRectangle(cornerRadius:20).stroke(HomeTheme.accent.opacity(0.16)))}}

/// A fresh cryptographically secure nonce binds the Apple credential to the
/// Supabase ID-token exchange and prevents replay of a captured identity token.
enum AppleLoginNonce {
    static func make() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            fatalError("Secure randomness is required for Apple sign-in")
        }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    static func hash(_ nonce: String) -> String {
        SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
