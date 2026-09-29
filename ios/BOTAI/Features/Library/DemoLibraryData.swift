import Foundation

struct DemoMaterial: Identifiable { let id=UUID(); let title:String; let description:String; let kind:String; let count:String; let source:String; let subject:String; let details:[String]; let sample:[String] }
struct DemoGroup: Identifiable { let id=UUID(); let title:String; let owner:String; let task:String; let materials:Int }

struct DemoLibraryData {
    let materials = [
        DemoMaterial(title:"Кислоты и кислотные остатки",description:"Формулы, названия, кислотные остатки и заряды",kind:"Справочник",count:"48 знаний · 144 вопроса",source:"Мой",subject:"Химия",details:["Название → формула","Формула → название","Название → остаток"],sample:["Серная кислота — H₂SO₄ — SO₄²⁻","Азотная кислота — HNO₃ — NO₃⁻"]),
        DemoMaterial(title:"Свойства кислот",description:"Основные реакции и химические свойства кислот",kind:"Опросник",count:"36 вопросов",source:"Библиотека",subject:"Химия",details:["Карточки","Один правильный ответ","Несколько правильных"],sample:["С чем реагируют кислоты?","Выберите свойства серной кислоты"]),
        DemoMaterial(title:"Органическая химия · формулы",description:"Номенклатура и структурные формулы",kind:"Справочник",count:"72 знания · 216 вопросов",source:"Файл",subject:"Химия",details:["Название ↔ формула","Формула → класс вещества","Есть изображения"],sample:["Этанол — C₂H₅OH","Этан — C₂H₆"]),
        DemoMaterial(title:"Строение атома",description:"Частицы, электронные оболочки и конфигурации",kind:"Опросник",count:"42 вопроса",source:"Библиотека",subject:"Физика",details:["Карточки","Тест с одним ответом"],sample:["Какой заряд имеет электрон?","Что определяет порядковый номер элемента?"])
    ]
    let groups = [
        DemoGroup(title:"10Б · Химия",owner:"Анна Сергеевна · преподаватель",task:"Кислоты к пятнице · 100 вопросов",materials:7),
        DemoGroup(title:"Подготовка к ЕГЭ",owner:"Родитель",task:"Химия · 40 минут в день",materials:14)
    ]
}
