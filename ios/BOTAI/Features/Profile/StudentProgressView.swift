import SwiftUI

struct StudentProgressView: View {
    @Environment(LearningStore.self) private var learning
    @Environment(CourseStore.self) private var courses
    var body:some View { ZStack { ProfileBG(); ScrollView { VStack(spacing:14) { header; emptyAnalytics }.padding(16) } }.navigationTitle("Мой прогресс").navigationBarTitleDisplayMode(.inline) }
    private var header:some View { VStack(alignment:.leading,spacing:6){Text("ДИНАМИКА ОБУЧЕНИЯ").font(.caption.bold()).foregroundStyle(.cyan);Text("Здесь будет только реальная статистика").font(.headline).foregroundStyle(.white);Text("BOTAI будет строить её по истории учебных сессий, ответам и изменению освоения — без демонстрационных процентов.").font(.caption).foregroundStyle(.white.opacity(0.58))}.frame(maxWidth:.infinity,alignment:.leading).padding(16).profileCard() }
    private var emptyAnalytics:some View { VStack(spacing:13){Image(systemName:"chart.line.uptrend.xyaxis").font(.system(size:38)).foregroundStyle(.cyan);Text("Пока недостаточно данных").font(.headline).foregroundStyle(.white);Text("После реальных учебных сессий здесь появятся минуты по дням, динамика освоения, план/факт целей и слабые темы.").font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.6))}.frame(maxWidth:.infinity).padding(28).profileCard() }
}
