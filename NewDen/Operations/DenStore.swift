import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class DenStore {
    let container: ModelContainer
    let context: ModelContext
    private(set) var undoManager: UndoManager
    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var saveError: String?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let saveChanges: (ModelContext) throws -> Void

    init(container: ModelContainer, now: @escaping () -> Date = { .now },
         saveChanges: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        self.container = container
        context = container.mainContext
        context.autosaveEnabled = false
        let manager = UndoManager()
        manager.groupsByEvent = false
        undoManager = manager
        // SwiftData automatic snapshots lose inverse relationships on undo on the tested runtime.
        // Register one value snapshot per operation with the window UndoManager instead.
        context.undoManager = nil
        self.now = now
        self.saveChanges = saveChanges
    }

    func connectUndoManager(_ manager: UndoManager?) {
        guard let manager, manager !== undoManager else { return }
        manager.groupsByEvent = false
        undoManager = manager
        // SwiftData automatic snapshots lose inverse relationships on undo on the tested runtime.
        // Register one value snapshot per operation with the window UndoManager instead.
        context.undoManager = nil
        refreshUndoState()
    }

    func refreshUndoState() {
        canUndo = undoManager.canUndo
        canRedo = undoManager.canRedo
    }

    @discardableResult
    func createPaddy(kind: DenKind) throws -> Den {
        let date = now()
        let paddy = Paddy(now: date)
        return try perform("田んぼを作る", paddy: paddy) {
            context.insert(paddy)
            let den = makeDen(kind: kind, paddy: paddy, now: date)
            let content = Content(text: kind == .threeGoodThings ? Self.dateTitle(date) : "", now: date)
            context.insert(content)
            den.themeContent = content
            return den
        }
    }

    func write(den: Den, position: Int, text: String) throws {
        let paddy = try validate(den)
        let slot = den.orderedSlots.first { $0.position == position }
        guard position == 0 || slot != nil else { throw DenStoreError.invalidTarget }
        let content = position == 0 ? den.theme : slot?.content
        guard content?.text != text else { return }
        try perform("マスを書く", paddy: paddy) {
            let date = now()
            let target: Content
            if let content { target = content } else {
                target = Content(now: date)
                context.insert(target)
                if position == 0 {
                    if let parentSlot = den.parentSlot { parentSlot.content = target }
                    else { den.themeContent = target }
                } else { slot?.content = target }
            }
            target.text = text
            target.updatedAt = date
            for themedDen in target.themedDens ?? [] { touch(themedDen, at: date) }
            for referringSlot in target.slots ?? [] {
                if let owner = referringSlot.owner { touch(owner, at: date) }
                if let child = referringSlot.child { touch(child, at: date) }
            }
            touch(den, at: date)
        }
    }

    func changeKind(_ den: Den, to kind: DenKind) throws {
        let paddy = try validate(den)
        guard den.kind != kind else { return }
        guard den.isIncomplete else { throw DenStoreError.completedKind }
        try perform("型を変える", paddy: paddy) {
            den.kindRaw = kind.rawValue
            let date = now()
            if kind == .threeGoodThings, den.parentSlot == nil, let theme = den.themeContent, theme.isBlank {
                theme.text = Self.dateTitle(den.createdAt)
                theme.updatedAt = date
            }
            touch(den, at: date)
        }
    }

    @discardableResult
    func createChild(in slot: Slot, kind: DenKind) throws -> Den {
        guard let owner = slot.owner, let paddy = owner.paddy else { throw DenStoreError.invalidTarget }
        _ = try validate(owner)
        guard slot.child == nil else { throw DenStoreError.occupied }
        guard owner.depth < 3 else { throw DenStoreError.maximumDepth }
        guard !owner.isIncomplete, slot.content?.isBlank == false else { throw DenStoreError.incomplete }
        return try perform("子の田を作る", paddy: paddy) {
            let date = now()
            let child = makeDen(kind: kind, paddy: paddy, now: date)
            slot.child = child
            touch(owner, at: date)
            return child
        }
    }

    func delete(_ den: Den) throws {
        let paddy = try validate(den)
        // Fetch before mutating so a fetch failure cannot leave half an operation.
        let contents = try context.fetch(FetchDescriptor<Content>())
        try perform("田を消す", paddy: paddy) {
            if let parent = den.parentSlot?.owner {
                context.delete(den)
                touch(parent, at: now())
            } else if let paddy = den.paddy {
                context.delete(paddy)
            }
            context.processPendingChanges()
            for content in contents where (content.slots ?? []).isEmpty && (content.themedDens ?? []).isEmpty {
                context.delete(content)
            }
        }
    }

    func undo() throws {
        guard saveError == nil else { throw DenStoreError.pendingSave }
        undoManager.undo()
        refreshUndoState()
        if saveError != nil { throw DenStoreError.pendingSave }
    }

    func redo() throws {
        guard saveError == nil else { throw DenStoreError.pendingSave }
        undoManager.redo()
        refreshUndoState()
        if saveError != nil { throw DenStoreError.pendingSave }
    }

    // History restoration saves immediately, including system shake / keyboard actions.
    func saveAfterHistoryChange() throws {
        defer { refreshUndoState() }
        context.processPendingChanges()
        try persist()
    }

    func retrySave() throws {
        defer { refreshUndoState() }
        try persist()
    }

    private func perform<T>(_ name: String, paddy: Paddy, change: () -> T) throws -> T {
        guard saveError == nil else { throw DenStoreError.pendingSave }
        let snapshot = paddy.modelContext == nil ? nil : PaddySnapshot(paddy)
        let paddyID = paddy.id
        undoManager.beginUndoGrouping()
        defer {
            undoManager.endUndoGrouping()
            refreshUndoState()
        }
        let result = change()
        registerHistory(paddyID: paddyID, snapshot: snapshot, name: name)
        try persist()
        return result
    }

    func reportHistoryError(_ error: Error) {
        saveError = "元に戻す操作を保存できませんでした。\n\(error.localizedDescription)"
        refreshUndoState()
    }

    private func persist() throws {
        do {
            try saveChanges(context)
            saveError = nil
        } catch {
            saveError = "変更を保存できませんでした。内容はこの画面に保持されています。\n\(error.localizedDescription)"
            throw error
        }
    }

    private func validate(_ den: Den) throws -> Paddy {
        guard den.modelContext === context, !den.isDeleted, let paddy = den.paddy else { throw DenStoreError.invalidTarget }
        return paddy
    }

    private func makeDen(kind: DenKind, paddy: Paddy, now: Date) -> Den {
        let den = Den(kind: kind, now: now)
        context.insert(den)
        paddy.dens = (paddy.dens ?? []) + [den]
        var slots: [Slot] = []
        for position in 1...3 {
            let slot = Slot(position: position)
            context.insert(slot)
            slots.append(slot)
        }
        den.slots = slots
        return den
    }

    private func touch(_ den: Den, at date: Date) {
        den.updatedAt = date
        den.paddy?.updatedAt = date
    }

    static func dateTitle(_ date: Date, timeZone: TimeZone = .current) -> String {
        let style = Date.FormatStyle(locale: Locale(identifier: "ja_JP"), calendar: Calendar(identifier: .gregorian), timeZone: timeZone)
        return date.formatted(style.year().month(.wide).day()) + "（" + date.formatted(style.weekday(.abbreviated)) + "）"
    }
}
