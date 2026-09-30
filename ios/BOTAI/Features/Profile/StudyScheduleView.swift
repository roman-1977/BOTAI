import SwiftUI

struct StudyScheduleView: View {
    @Environment(StudyProfileStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var defaultMinutes = 30
    @State private var advanced = false
    @State private var days = Array(repeating: 30, count: 7)
    private let names = ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
    private let calendarWeekdays = [2,3,4,5,6,7,1]

    var body: some View {
        ZStack {
            LinearGradient(colors:[Color(red:0.015,green:0.035,blue:0.12),Color(red:0.03,green:0.08,blue:0.18),.black],startPoint:.top,endPoint:.bottom).ignoresSafeArea()
            ScrollView { VStack(spacing:16) {
                VStack(alignment:.leading,spacing:7) {
                    Text("МОЙ РЕЖИМ ОБУЧЕНИЯ").font(.caption.bold()).foregroundStyle(.cyan)
                    Text("Сколько времени ты обычно готов уделять BOTAI в день.").font(.headline).foregroundStyle(.white)
                    Text("Это общий бюджет для всех целей. Планировщик распределит его между ними и пересчитает нагрузку после пропусков.").font(.caption).foregroundStyle(.white.opacity(0.6))
                }.frame(maxWidth:.infinity,alignment:.leading).padding(16).scheduleCard()
                VStack(spacing:14) {
                    Text("\(defaultMinutes) мин").font(.system(size:40,weight:.bold,design:.rounded)).foregroundStyle(.cyan)
                    HStack { ForEach([15,30,45,60],id:\.self) { value in Button("\(value)"){defaultMinutes=value;if !advanced{days=Array(repeating:value,count:7)}}.buttonStyle(.borderedProminent).tint(defaultMinutes == value ? .cyan : .white.opacity(0.08)).foregroundStyle(defaultMinutes == value ? .black : .white) } }
                    Stepper("Точно: \(defaultMinutes) минут",value:$defaultMinutes,in:5...240,step:5).foregroundStyle(.white).onChange(of:defaultMinutes){_,v in if !advanced{days=Array(repeating:v,count:7)}}
                }.padding(16).scheduleCard()
                Toggle("Настроить дни отдельно",isOn:$advanced).tint(.cyan).foregroundStyle(.white).padding(16).scheduleCard()
                if advanced { VStack(spacing:0) { ForEach(0..<7,id:\.self){i in HStack{Text(names[i]).font(.headline).frame(width:35,alignment:.leading);Spacer();Stepper("\(days[i]) мин",value:$days[i],in:0...240,step:5).fixedSize()}.foregroundStyle(.white).padding(.vertical,8);if i<6{Divider().overlay(.cyan.opacity(0.15))}} }.padding(.horizontal,16).scheduleCard() }
                let weekly = advanced ? days.reduce(0,+) : defaultMinutes*7
                HStack { Label("\(weekly/60) ч \(weekly%60) мин в неделю",systemImage:"calendar");Spacer() }.font(.caption.bold()).foregroundStyle(.cyan).padding(14).scheduleCard()
            }.padding(16) }
        }.navigationTitle("Режим обучения").navigationBarTitleDisplayMode(.inline).toolbar { Button("Сохранить") { let custom = advanced ? zip(calendarWeekdays,days).map{StudyDayPlan(weekday:$0.0,minutes:$0.1)} : [];store.save(defaultMinutes:defaultMinutes,customDays:custom);dismiss() } }.onAppear { defaultMinutes=store.profile.defaultDailyMinutes;advanced = !store.profile.customDays.isEmpty;days=calendarWeekdays.map{store.profile.minutes(for:$0)} }
    }
}
private extension View { func scheduleCard()->some View { background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(.cyan.opacity(0.18))) } }
