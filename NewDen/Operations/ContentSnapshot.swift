import Foundation

struct ContentSnapshot {
    let id: UUID
    let text: String
    let createdAt: Date
    let updatedAt: Date

    init(_ content: Content) {
        id = content.id; text = content.text; createdAt = content.createdAt; updatedAt = content.updatedAt
    }
}
