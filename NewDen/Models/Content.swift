import Foundation
import SwiftData

extension NewDenSchemaV1 {
    @Model final class Content {
        var id: UUID = UUID()
        var text: String = ""
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        @Relationship(deleteRule: .nullify, inverse: \Slot.content)
        var slots: [Slot]? = []
        @Relationship(deleteRule: .nullify, inverse: \Den.themeContent)
        var themedDens: [Den]? = []

        init(text: String = "", now: Date) {
            self.text = text; createdAt = now; updatedAt = now
        }
        var isBlank: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
