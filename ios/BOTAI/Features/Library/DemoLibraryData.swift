import Foundation

struct DemoCourse: Identifiable { let id=UUID(); let title:String; let sections:Int; let materials:Int; let icon:String; let task:String? }
struct DemoMaterial: Identifiable { let id=UUID(); let title:String; let description:String; let kind:String; let count:String; let source:String }
struct DemoGroup: Identifiable { let id=UUID(); let title:String; let owner:String; let task:String; let materials:Int }

struct DemoLibraryData {
    let courses = [
        DemoCourse(title:"ЕГЭ · Химия 2027",sections:5,materials:12,icon:"atom",task:"40 мин · 20 вопросов в день"),
        DemoCourse(title:"Повторить к октябрю",sections:3,materials:6,icon:"calendar",task:"Освоить 85% до 15 октября"),
        DemoCourse(title:"Сложные темы",sections:4,materials:8,icon:"bolt.fill",task:nil)
    ]
    let materials = [
        DemoMaterial(title:"Кислоты и кислотные остатки",description:"Формулы, названия, кислотные остатки и заряды",kind:"Справочник",count:"48 знаний · 144 вопроса",source:"Мой"),
        DemoMaterial(title:"Свойства кислот",description:"Основные реакции и химические свойства кислот",kind:"Опросник",count:"36 вопросов",source:"Библиотека"),
        DemoMaterial(title:"Органическая химия · формулы",description:"Номенклатура и структурные формулы",kind:"Справочник",count:"72 знания · 216 вопросов",source:"Файл"),
        DemoMaterial(title:"Строение атома",description:"Частицы, электронные оболочки и конфигурации",kind:"Опросник",count:"42 вопроса",source:"Библиотека")
    ]
    let groups = [
        DemoGroup(title:"10Б · Химия",owner:"Анна Сергеевна · преподаватель",task:"Кислоты к пятнице · 100 вопросов",materials:7),
        DemoGroup(title:"Подготовка к ЕГЭ",owner:"Родитель",task:"Химия · 40 минут в день",materials:14)
    ]
}
