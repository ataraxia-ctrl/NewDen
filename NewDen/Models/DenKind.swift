import Foundation

enum DenKind: String, Codable, CaseIterable, Identifiable {
    case goal, event, feeling, question, dilemma, threeGoodThings

    var id: String { rawValue }
    var title: String {
        switch self {
        case .goal: "目標"
        case .event: "出来事"
        case .feeling: "感情"
        case .question: "問い"
        case .dilemma: "迷い"
        case .threeGoodThings: "Three Good Things"
        }
    }
    var themePrompt: String {
        switch self {
        case .goal: "目標"
        case .event: "今日あったこと"
        case .feeling: "今の気持ち"
        case .question: "問い"
        case .dilemma: "決めたいこと"
        case .threeGoodThings: "今日の日付"
        }
    }
    var elementPrompt: String {
        switch self {
        case .goal: "達成に必要な要素"
        case .event: "気づき・学び"
        case .feeling: "その理由"
        case .question: "仮説"
        case .dilemma: "判断の基準"
        case .threeGoodThings: "良かったこと"
        }
    }
}
