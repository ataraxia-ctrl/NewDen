import Foundation
import SwiftData

extension NewDenSchemaV1 {
    @Model final class Paddy {
        var id: UUID = UUID()
        var createdAt: Date = Date.now
        var updatedAt: Date = Date.now
        @Relationship(deleteRule: .cascade, inverse: \Den.paddy)
        var dens: [Den]? = []

        init(now: Date) { createdAt = now; updatedAt = now }
        var root: Den? { dens?.first { $0.parentSlot == nil } }
        var title: String { root?.displayTitle ?? "無題の田んぼ" }
    }
}
