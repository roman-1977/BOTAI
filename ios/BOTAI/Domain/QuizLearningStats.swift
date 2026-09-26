import Foundation
struct QuizLearningStats { let total:Int; let learned:Int; let attempts:Int; let known:Int; let hard:Int; let again:Int; let today:Int
    var coverage:Double { total == 0 ? 0 : Double(learned)/Double(total) }
    var knownRate:Double { attempts == 0 ? 0 : Double(known)/Double(attempts) }
}
