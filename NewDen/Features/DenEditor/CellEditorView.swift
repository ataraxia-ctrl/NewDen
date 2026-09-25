import SwiftUI

struct CellEditorView: View {
    let den: Den
    let position: Int
    let store: DenStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var draft: String
    @State private var childKind: DenKind = .goal
    @State private var errorMessage: String?
    @State private var submitted = false
    @FocusState private var isFocused: Bool

    init(den: Den, position: Int, store: DenStore) {
        self.den = den; self.position = position; self.store = store
        let text = position == 0 ? den.theme?.text : den.orderedSlots.first { $0.position == position }?.content?.text
        _draft = State(initialValue: text ?? "")
    }

    private var slot: Slot? { den.orderedSlots.first { $0.position == position } }
    private var title: String { position == 0 ? den.kind.themePrompt : "\(den.kind.elementPrompt) \(position)" }

    var body: some View {
        NavigationStack {
            Form {
                Section(title) {
                    TextField("ここに書く", text: $draft, axis: .vertical)
                        .lineLimit(6...)
                        .focused($isFocused)
                        .accessibilityIdentifier("cellText")
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                if store.saveError != nil {
                    Section {
                        Text("内容を保持しています。保存を再試行してください。")
                        Button("保存を再試行", action: commit)
                    }
                }
                if position > 0, den.depth < 3, !den.isIncomplete, slot?.child == nil {
                    Section("この要素を掘り下げる") {
                        Picker("子の田の型", selection: $childKind) {
                            ForEach(DenKind.allCases) { kind in Text(kind.title).tag(kind) }
                        }
                        Button("保存して子の田を作る", action: createChild)
                            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.saveError != nil)
                    }
                }
            }
            .navigationTitle("マスを書く")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { submitted = true; dismiss() }
                        .disabled(store.saveError != nil)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了", action: commit).accessibilityIdentifier("saveCell")
                }
            }
            .interactiveDismissDisabled()
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { commit() }
            }
            .task { isFocused = true }
        }
    }

    private func saveDraft() throws {
        if store.saveError != nil { try store.retrySave() }
        try store.write(den: den, position: position, text: draft)
    }

    private func commit() {
        guard !submitted else { return }
        do {
            try saveDraft()
            submitted = true
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    private func createChild() {
        guard let slot, !submitted else { return }
        do {
            try saveDraft()
            try store.createChild(in: slot, kind: childKind)
            submitted = true
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
