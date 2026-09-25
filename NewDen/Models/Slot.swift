import Foundation
import SwiftData

extension NewDenSchemaV1 {
    @Model final class Slot {
        var id: UUID = UUID()
        var position: Int = 1
        var owner: Den?
        var content: Content?
        @Relationship(deleteRule: .cascade, inverse: \Den.parentSlot)
        var child: Den?

        init(position: Int) { self.position = position }
    }
}
