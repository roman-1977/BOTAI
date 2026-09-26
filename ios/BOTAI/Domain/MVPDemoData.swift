import Foundation

enum MVPDemoData {
    struct Plan: Identifiable { let id:UUID; let title:String; let subtitle:String; let progress:Double; let today:Int; let minutes:Int; let due:Int; let fresh:Int }
    static let acidID=UUID(uuidString:"A1000000-0000-4000-8000-000000000001")!
    static let englishID=UUID(uuidString:"A1000000-0000-4000-8000-000000000002")!
    static let geoID=UUID(uuidString:"A1000000-0000-4000-8000-000000000003")!
    static let plans=[Plan(id:acidID,title:"Кислоты и кислотные остатки",subtitle:"Химия · к 15 октября",progress:0.44,today:18,minutes:7,due:7,fresh:11),Plan(id:englishID,title:"Неправильные глаголы",subtitle:"Английский · 20 вопросов в день",progress:0.72,today:12,minutes:5,due:9,fresh:3),Plan(id:geoID,title:"Столицы Европы",subtitle:"География · без срока",progress:0.31,today:10,minutes:4,due:4,fresh:6)]
    static func questions(for plan:Plan)->[StudyQuestion] { let cards:[(String,String)] = plan.id == acidID ? [("Как называется кислотный остаток серной кислоты?","Сульфат, SO₄²⁻"),("Формула азотной кислоты?","HNO₃"),("Как называется остаток HCl?","Хлорид, Cl⁻"),("Формула угольной кислоты?","H₂CO₃"),("Как называется остаток фосфорной кислоты?","Фосфат, PO₄³⁻"),("Формула сернистой кислоты?","H₂SO₃"),("Как называется остаток HClO₄?","Перхлорат, ClO₄⁻"),("Формула уксусной кислоты?","CH₃COOH")] : plan.id == englishID ? [("go — Past Simple?","went"),("see — Past Simple?","saw"),("take — Past Simple?","took"),("write — Past Simple?","wrote"),("come — Past Simple?","came")] : [("Столица Испании?","Мадрид"),("Столица Португалии?","Лиссабон"),("Столица Австрии?","Вена"),("Столица Норвегии?","Осло"),("Столица Чехии?","Прага")]; return QuizQuestionFactory.questions(quizID:plan.id,cards:Array(cards.prefix(plan.today))) }
}
