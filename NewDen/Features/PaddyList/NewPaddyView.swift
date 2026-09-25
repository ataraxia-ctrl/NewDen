import SwiftUI

struct NewPaddyView: View {
    let store: DenStore
    let onCreate: (Den) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var kind: DenKind = .goal
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("型", selection: $kind) {
                    ForEach(DenKind.allCases) { kind in Text(kind.title).tag(kind) }
                }
                .pickerStyle(.inline)
                Section {
                    Text("主題：\(kind.themePrompt)")
                    Text("3つの要素：\(kind.elementPrompt)")
                } footer: { Text("型は、要素を3つ埋めるまで変更できます。") }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("田んぼを作る")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成", action: create).accessibilityIdentifier("confirmCreate")
                        .disabled(store.saveError != nil)
                }
            }
        }
    }

    private func create() {
        do {
            let den = try store.createPaddy(kind: kind)
            dismiss()
            onCreate(den)
        } catch {
            errorMessage = error.localizedDescription
            // A failed save retains the new paddy in the list; do not create a duplicate.
            if store.saveError != nil { dismiss() }
        }
    }
}
