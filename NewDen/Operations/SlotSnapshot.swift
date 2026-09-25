import Foundation

struct SlotSnapshot {
    let id: UUID
    let position: Int
    let contentID: UUID?
    let childID: UUID?

    init(_ slot: Slot) {
        id = slot.id; position = slot.position; contentID = slot.content?.id; childID = slot.child?.id
    }
}
