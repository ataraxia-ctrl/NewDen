import Foundation
import SwiftData

/// Value snapshots isolate one paddy's undo history from SwiftData's live object graph.
/// Only this implementation unit's local tree is captured; cross-paddy references are not yet supported.
struct PaddySnapshot {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let dens: [DenSnapshot]
    let contents: [ContentSnapshot]

    init(_ paddy: Paddy) {
        id = paddy.id; createdAt = paddy.createdAt; updatedAt = paddy.updatedAt
        dens = (paddy.dens ?? []).map(DenSnapshot.init)
        var unique: [UUID: Content] = [:]
        for den in paddy.dens ?? [] {
            if let theme = den.themeContent { unique[theme.id] = theme }
            for slot in den.slots ?? [] {
                if let content = slot.content { unique[content.id] = content }
            }
        }
        contents = unique.values.map(ContentSnapshot.init)
    }
}
