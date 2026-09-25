import Foundation
import SwiftData
import Testing
@testable import NewDen

@MainActor
struct DenStoreTests {
    private let date = Date(timeIntervalSince1970: 1_790_294_400) // 2026-09-25 UTC

    private func makeStore() throws -> DenStore {
        DenStore(container: try Persistence.makeContainer(inMemory: true), now: { date })
    }

    private func complete(_ den: Den, in store: DenStore) throws {
        for position in 1...3 { try store.write(den: den, position: position, text: "要素\(position)") }
    }

    @Test(arguments: DenKind.allCases)
    func creationHasExactlyOneRootAndThreeOrderedSlots(kind: DenKind) throws {
        let store = try makeStore()
        let den = try store.createPaddy(kind: kind)
        #expect(den.orderedSlots.map(\.position) == [1, 2, 3])
        #expect(den.paddy?.dens?.count == 1)
        #expect(den.paddy?.root === den)
        #expect(den.themeContent != nil)
        #expect(den.isIncomplete)
        #expect(den.depth == 0)
        #expect(den.kind == kind)
        #expect(den.theme?.isBlank == (kind != .threeGoodThings))
    }

    @Test(arguments: ["", "  ", "\n\t　"])
    func whitespacePreventsChildren(text: String) throws {
        let store = try makeStore()
        let den = try store.createPaddy(kind: .goal)
        try complete(den, in: store)
        try store.write(den: den, position: 3, text: text)
        #expect(den.isIncomplete)
        #expect(throws: DenStoreError.incomplete) {
            try store.createChild(in: den.orderedSlots[0], kind: .goal)
        }
    }

    @Test func childSharesContentAndUpdatesBothDens() throws {
        var clock = date
        let store = DenStore(container: try Persistence.makeContainer(inMemory: true), now: { clock })
        let den = try store.createPaddy(kind: .goal)
        try complete(den, in: store)
        let slot = den.orderedSlots[0]
        let child = try store.createChild(in: slot, kind: .threeGoodThings)
        #expect(child.themeContent == nil)
        #expect(child.theme === slot.content)
        #expect(child.paddy === den.paddy)
        #expect(child.theme?.text == "要素1")
        clock = date.addingTimeInterval(60)
        try store.write(den: child, position: 0, text: "共通の内容")
        #expect(slot.content?.text == "共通の内容")
        #expect(den.updatedAt == clock)
        #expect(child.updatedAt == clock)
        #expect(den.paddy?.updatedAt == clock)
        #expect(throws: DenStoreError.occupied) { try store.createChild(in: slot, kind: .goal) }
    }

    @Test func fourthLayerCannotCreateChild() throws {
        let store = try makeStore()
        var den = try store.createPaddy(kind: .goal)
        for _ in 0..<3 {
            try complete(den, in: store)
            den = try store.createChild(in: den.orderedSlots[0], kind: .goal)
        }
        try complete(den, in: store)
        #expect(den.depth == 3)
        #expect(throws: DenStoreError.maximumDepth) { try store.createChild(in: den.orderedSlots[0], kind: .goal) }
    }

    @Test func kindChangesOnlyWhileCurrentlyIncomplete() throws {
        let store = try makeStore()
        let den = try store.createPaddy(kind: .goal)
        try complete(den, in: store)
        #expect(throws: DenStoreError.completedKind) { try store.changeKind(den, to: .feeling) }
        try store.write(den: den, position: 3, text: "")
        try store.changeKind(den, to: .feeling)
        #expect(den.kind == .feeling)
    }

    @Test func japaneseDateAndExistingThemeArePreserved() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-25T12:00:00Z"))
        let formatted = DenStore.dateTitle(date, timeZone: try #require(TimeZone(identifier: "Asia/Tokyo")))
        #expect(formatted == "2026年9月25日（金）")
        let store = try makeStore()
        let den = try store.createPaddy(kind: .goal)
        try store.changeKind(den, to: .threeGoodThings)
        #expect(den.theme?.text == DenStore.dateTitle(den.createdAt))
        try store.changeKind(den, to: .goal)
        try store.write(den: den, position: 0, text: "残したい主題")
        try store.changeKind(den, to: .threeGoodThings)
        #expect(den.theme?.text == "残したい主題")
    }

    @Test func editIsOneUndoAndRedoIncludingNewContent() throws {
        let store = try makeStore()
        let den = try store.createPaddy(kind: .goal)
        store.undoManager.removeAllActions()
        try store.write(den: den, position: 1, text: "ひとつの編集\n複数行")
        #expect(store.canUndo)
        try store.undo()
        #expect(try store.context.fetchCount(FetchDescriptor<Slot>()) == 3)
        #expect(try store.context.fetchCount(FetchDescriptor<Den>()) == 1)
        let firstSlot = try #require(den.orderedSlots.first)
        #expect(firstSlot.content == nil)
        #expect(store.canUndo == false)
        #expect(store.canRedo)
        try store.redo()
        #expect(den.orderedSlots[0].content?.text == "ひとつの編集\n複数行")
    }

    @Test func creationAndChildCreationUndoRedoKeepTreeShape() throws {
        let store = try makeStore()
        try store.createPaddy(kind: .goal)
        try store.undo()
        #expect(try store.context.fetchCount(FetchDescriptor<Paddy>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<Content>()) == 0)
        try store.redo()
        let paddy = try #require(store.context.fetch(FetchDescriptor<Paddy>()).first)
        let root = try #require(paddy.root)
        try complete(root, in: store)
        try store.createChild(in: root.orderedSlots[0], kind: .question)
        try store.undo()
        #expect(paddy.dens?.count == 1)
        #expect(root.orderedSlots[0].child == nil)
        #expect(root.orderedSlots[0].content?.text == "要素1")
        try store.redo()
        #expect(paddy.dens?.count == 2)
        #expect(root.orderedSlots[0].child?.theme === root.orderedSlots[0].content)
        #expect(root.orderedSlots[0].child?.orderedSlots.count == 3)
    }

    @Test func existingTextAndKindUndoRestoreExactValues() throws {
        let store = try makeStore()
        let root = try store.createPaddy(kind: .goal)
        try store.write(den: root, position: 0, text: "元の主題")
        try store.write(den: root, position: 0, text: "新しい主題")
        try store.undo()
        #expect(root.theme?.text == "元の主題")
        try store.redo()
        #expect(root.theme?.text == "新しい主題")
        try store.changeKind(root, to: .question)
        try store.undo()
        #expect(root.kind == .goal)
        #expect(root.theme?.text == "新しい主題")
    }

    @Test func deletingRootCleansAllModelsAndUndoRestoresGraph() throws {
        let store = try makeStore()
        let root = try store.createPaddy(kind: .goal)
        try complete(root, in: store)
        let child = try store.createChild(in: root.orderedSlots[0], kind: .question)
        try complete(child, in: store)
        store.undoManager.removeAllActions()
        try store.delete(root)
        #expect(try store.context.fetchCount(FetchDescriptor<Paddy>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<Den>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<Slot>()) == 0)
        #expect(try store.context.fetchCount(FetchDescriptor<Content>()) == 0)
        try store.undo()
        let paddy = try #require(store.context.fetch(FetchDescriptor<Paddy>()).first)
        let restoredRoot = try #require(paddy.root)
        #expect(paddy.dens?.count == 2)
        #expect(restoredRoot.orderedSlots.map(\.position) == [1, 2, 3])
        #expect(restoredRoot.orderedSlots[0].child?.theme === restoredRoot.orderedSlots[0].content)
        #expect(try store.context.fetchCount(FetchDescriptor<Content>()) == 7)
        #expect(store.canUndo == false)
        try store.redo()
        #expect(try store.context.fetchCount(FetchDescriptor<Content>()) == 0)
    }

    @Test func deletingChildKeepsParentContent() throws {
        let store = try makeStore()
        let root = try store.createPaddy(kind: .goal)
        try complete(root, in: store)
        let child = try store.createChild(in: root.orderedSlots[0], kind: .goal)
        try complete(child, in: store)
        try store.delete(child)
        #expect(root.orderedSlots[0].child == nil)
        #expect(root.orderedSlots[0].content?.text == "要素1")
        #expect(try store.context.fetchCount(FetchDescriptor<Content>()) == 4)
        try store.undo()
        #expect(root.orderedSlots[0].child?.orderedSlots.count == 3)
    }

    @Test func saveFailureKeepsChangesAndRetryDoesNotDuplicateUndo() throws {
        var fails = false
        let store = DenStore(container: try Persistence.makeContainer(inMemory: true), saveChanges: { context in
            if fails { throw CocoaError(.fileWriteOutOfSpace) }
            try context.save()
        })
        let den = try store.createPaddy(kind: .goal)
        store.undoManager.removeAllActions()
        fails = true
        #expect(throws: CocoaError(.fileWriteOutOfSpace)) { try store.write(den: den, position: 1, text: "失わない") }
        #expect(den.orderedSlots[0].content?.text == "失わない")
        #expect(store.saveError != nil)
        #expect(throws: DenStoreError.pendingSave) { try store.createPaddy(kind: .goal) }
        fails = false
        try store.retrySave()
        #expect(store.saveError == nil)
        try store.undo()
        #expect(try store.context.fetchCount(FetchDescriptor<Slot>()) == 3)
        #expect(try store.context.fetchCount(FetchDescriptor<Den>()) == 1)
        let firstSlot = try #require(den.orderedSlots.first)
        #expect(firstSlot.content == nil)
        #expect(store.canUndo == false)
    }

    @Test func diskStoreReopensAfterEditsAndUndo() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "NewDen.store")
        try writeDiskFixture(url)
        let store = DenStore(container: try Persistence.makeContainer(url: url))
        let paddy = try #require(store.context.fetch(FetchDescriptor<Paddy>()).first)
        let root = try #require(paddy.root)
        #expect(root.theme?.text == "永続化")
        #expect(root.orderedSlots.map(\.position) == [1, 2, 3])
        let child = try #require(root.orderedSlots[0].child)
        #expect(child.theme?.text == "要素1")
        #expect(child.theme === root.orderedSlots[0].content)
        #expect(child.themeContent == nil)
        #expect(paddy.dens?.count == 2)
        #expect(store.canUndo == false)
    }

    private func writeDiskFixture(_ url: URL) throws {
        let store = DenStore(container: try Persistence.makeContainer(url: url))
        let den = try store.createPaddy(kind: .goal)
        try store.write(den: den, position: 0, text: "永続化")
        try complete(den, in: store)
        let child = try store.createChild(in: den.orderedSlots[0], kind: .question)
        try store.write(den: child, position: 0, text: "取り消す")
        try store.undo()
        try store.delete(child)
        try store.undo()
        store.undoManager.removeAllActions()
    }
}
