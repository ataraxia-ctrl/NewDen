import Foundation
import SwiftData

extension DenStore {
    func registerHistory(paddyID: UUID, snapshot: PaddySnapshot?, name: String) {
        undoManager.registerUndo(withTarget: self) { store in
            MainActor.assumeIsolated {
                store.restoreHistory(paddyID: paddyID, snapshot: snapshot, name: name)
            }
        }
        undoManager.setActionName(name)
    }

    private func restoreHistory(paddyID: UUID, snapshot: PaddySnapshot?, name: String) {
        do {
            let descriptor = FetchDescriptor<Paddy>(predicate: #Predicate { $0.id == paddyID })
            let existing = try context.fetch(descriptor).first
            let inverse = existing.map(PaddySnapshot.init)
            let unusedCandidates = try context.fetch(FetchDescriptor<Content>())
            restore(snapshot, replacing: existing)
            context.processPendingChanges()
            for content in unusedCandidates where (content.slots ?? []).isEmpty && (content.themedDens ?? []).isEmpty {
                context.delete(content)
            }
            registerHistory(paddyID: paddyID, snapshot: inverse, name: name)
            try saveAfterHistoryChange()
        } catch {
            reportHistoryError(error)
        }
    }

    private func restore(_ snapshot: PaddySnapshot?, replacing existing: Paddy?) {
        guard let snapshot else {
            if let existing { context.delete(existing) }
            return
        }
        let paddy = existing ?? Paddy(now: snapshot.createdAt)
        if existing == nil { context.insert(paddy) }
        paddy.id = snapshot.id
        paddy.createdAt = snapshot.createdAt
        paddy.updatedAt = snapshot.updatedAt
        let oldDens = paddy.dens ?? []
        let oldSlots = oldDens.flatMap { $0.slots ?? [] }
        var dens = Dictionary(uniqueKeysWithValues: oldDens.map { ($0.id, $0) })
        var slots = Dictionary(uniqueKeysWithValues: oldSlots.map { ($0.id, $0) })
        var contents: [UUID: Content] = [:]
        for den in oldDens {
            if let content = den.themeContent { contents[content.id] = content }
            for slot in den.slots ?? [] {
                if let content = slot.content { contents[content.id] = content }
            }
        }
        // Detach edges before deleting any nodes, so cascade cannot remove a retained child.
        for slot in oldSlots { slot.child = nil }
        for item in snapshot.contents {
            let content = contents[item.id] ?? Content(now: item.createdAt)
            if content.modelContext == nil { context.insert(content) }
            content.id = item.id; content.text = item.text
            content.createdAt = item.createdAt; content.updatedAt = item.updatedAt
            contents[item.id] = content
        }
        for item in snapshot.dens {
            let den = dens[item.id] ?? Den(kind: .goal, now: item.createdAt)
            if den.modelContext == nil { context.insert(den) }
            den.id = item.id; den.kindRaw = item.kindRaw
            den.createdAt = item.createdAt; den.updatedAt = item.updatedAt
            den.paddy = paddy
            den.themeContent = item.themeID.flatMap { contents[$0] }
            dens[item.id] = den
            var restoredSlots: [Slot] = []
            for item in item.slots {
                let slot = slots[item.id] ?? Slot(position: item.position)
                if slot.modelContext == nil { context.insert(slot) }
                slot.id = item.id; slot.position = item.position
                slot.content = item.contentID.flatMap { contents[$0] }
                slots[item.id] = slot
                restoredSlots.append(slot)
            }
            den.slots = restoredSlots
        }
        for item in snapshot.dens {
            for slot in item.slots { slots[slot.id]?.child = slot.childID.flatMap { dens[$0] } }
        }
        let denIDs = Set(snapshot.dens.map(\.id))
        let slotIDs = Set(snapshot.dens.flatMap(\.slots).map(\.id))
        for slot in oldSlots where !slotIDs.contains(slot.id) { context.delete(slot) }
        for den in oldDens where !denIDs.contains(den.id) { context.delete(den) }
        paddy.dens = snapshot.dens.compactMap { dens[$0.id] }
    }
}
