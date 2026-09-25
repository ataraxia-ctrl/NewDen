import Foundation

enum DenStoreError: LocalizedError, Equatable {
    case incomplete, maximumDepth, occupied, completedKind, invalidTarget, pendingSave
    var errorDescription: String? {
        switch self {
        case .incomplete: "3つの要素を埋めると、子の田を作れます。"
        case .maximumDepth: "田んぼは4階層までです。"
        case .occupied: "このマスにはすでに子の田があります。"
        case .completedKind: "完成した田の型は変更できません。"
        case .invalidTarget: "編集する田が見つかりません。"
        case .pendingSave: "保存できていない変更があります。保存を再試行してください。"
        }
    }
}
