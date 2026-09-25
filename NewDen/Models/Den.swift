import Foundation
import SwiftData

extension NewDenSchemaV1 {
    @Model final class Den {
        var id: UUID = UUID()
        var kindRaw: String = DenKind.goal.rawValue
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        var paddy: Paddy?
        var parentSlot: Slot?
        var themeContent: Content?
        @Relationship(deleteRule: .cascade, inverse: \Slot.owner)
        var slots: [Slot]? = []

        init(kind: DenKind, now: Date) {
            kindRaw = kind.rawValue; createdAt = now; updatedAt = now
        }
        var kind: DenKind { DenKind(rawValue: kindRaw) ?? .goal }
        var theme: Content? { parentSlot?.content ?? themeContent }
        var orderedSlots: [Slot] { (slots ?? []).sorted { $0.position < $1.position } }
        var isIncomplete: Bool { orderedSlots.count != 3 || orderedSlots.contains { $0.content?.isBlank != false } }
        var depth: Int { (parentSlot?.owner.map { $0.depth + 1 }) ?? 0 }
        var displayTitle: String {
            guard let theme, !theme.isBlank else { return "無題の田んぼ" }
            return theme.text
        }
    }
}
