import SwiftUI

struct StoreStatusView: View {
    let store: DenStore
    let deletionNotice: Bool

    var body: some View {
        VStack(spacing: 8) {
            if let error = store.saveError {
                Text(error).font(.callout).accessibilityIdentifier("saveError")
                Button("保存を再試行", action: retry)
            } else {
                HStack {
                    if deletionNotice { Text("削除を取り消せます").font(.caption) }
                    Spacer()
                    Button("元に戻す", systemImage: "arrow.uturn.backward", action: undo)
                        .frame(minWidth: 44, minHeight: 44)
                        .disabled(!store.canUndo).accessibilityIdentifier("undo")
                    Button("やり直す", systemImage: "arrow.uturn.forward", action: redo)
                        .frame(minWidth: 44, minHeight: 44)
                        .disabled(!store.canRedo).accessibilityIdentifier("redo")
                }
                .labelStyle(.iconOnly)
            }
        }
        .padding()
        .background(.bar)
    }

    private func retry() { do { try store.retrySave() } catch { } }
    private func undo() { do { try store.undo() } catch { } }
    private func redo() { do { try store.redo() } catch { } }
}
