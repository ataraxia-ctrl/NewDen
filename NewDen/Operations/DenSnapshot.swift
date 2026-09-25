import Foundation

struct DenSnapshot {
    let id: UUID
    let kindRaw: String
    let createdAt: Date
    let updatedAt: Date
    let themeID: UUID?
    let slots: [SlotSnapshot]

    init(_ den: Den) {
        id = den.id; kindRaw = den.kindRaw; createdAt = den.createdAt; updatedAt = den.updatedAt
        themeID = den.themeContent?.id
        slots = den.orderedSlots.map(SlotSnapshot.init)
    }
}
