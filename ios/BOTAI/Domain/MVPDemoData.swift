import Foundation

enum MVPDemoData {
    struct Plan: Identifiable { let id=UUID(); let title:String; let subtitle:String; let progress:Double; let today:Int; let minutes:Int; let due:Int; let fresh:Int }
    static let plans = [
        Plan(title:"Кислоты и кислотные остатки",subtitle:"Химия · к 15 октября",progress:0.44,today:18,minutes:7,due:7,fresh:11),
        Plan(title:"Неправильные глаголы",subtitle:"Английский · 20 вопросов в день",progress:0.72,today:12,minutes:5,due:9,fresh:3),
        Plan(title:"Столицы Европы",subtitle:"География · без срока",progress:0.31,today:10,minutes:4,due:4,fresh:6)
    ]
    static let recent = ["Кислоты и кислотные остатки","Неправильные глаголы","Столицы Европы"]
}
