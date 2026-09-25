import SwiftData
import SwiftUI

struct PaddyListView: View {
    let store: DenStore
    @Environment(\.undoManager) private var systemUndoManager
    @Query(sort: \Paddy.updatedAt, order: .reverse) private var paddies: [Paddy]
    @State private var path: [UUID] = []
    @State private var showsCreation = false
    @State private var operationError: String?
    @State private var showsError = false
    @State private var deletionNotice = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(paddies) { paddy in
                    if let root = paddy.root {
                        NavigationLink(value: root.id) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(paddy.title).font(.headline).lineLimit(2)
                                Text("\(root.kind.title) · \(root.isIncomplete ? "未完" : "完成")")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text(paddy.updatedAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                        .swipeActions {
                            Button("削除", role: .destructive) { delete(root) }
                        }
                    }
                }
            }
            .overlay {
                if paddies.isEmpty {
                    ContentUnavailableView("最初の田んぼをつくる", systemImage: "square.split.2x2", description: Text("ひとつの主題と、3つの要素。\n書きかけのままでも残せます。"))
                }
            }
            .navigationTitle("田んぼ")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("田んぼを作る", systemImage: "plus") { showsCreation = true }
                        .accessibilityIdentifier("createPaddy")
                        .disabled(store.saveError != nil)
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let den = paddies.flatMap({ $0.dens ?? [] }).first(where: { $0.id == id }) {
                    DenEditorView(den: den, store: store)
                } else {
                    ContentUnavailableView("この田は削除されました", systemImage: "square.dashed", description: Text("元に戻すと、もう一度開けます。"))
                }
            }
            .sheet(isPresented: $showsCreation) {
                NewPaddyView(store: store) { den in path.append(den.id) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            StoreStatusView(store: store, deletionNotice: deletionNotice)
        }
        .task(id: deletionNotice) {
            guard deletionNotice else { return }
            do {
                try await Task.sleep(for: .seconds(5))
                deletionNotice = false
            } catch { }
        }
        .onChange(of: systemUndoManager, initial: true) { _, manager in store.connectUndoManager(manager) }
        .alert("操作できませんでした", isPresented: $showsError) { } message: { Text(operationError ?? "") }
    }

    private func delete(_ den: Den) {
        do { try store.delete(den); deletionNotice = true }
        catch { if store.saveError == nil { operationError = error.localizedDescription; showsError = true } }
    }

}

#Preview {
    if let store = try? Persistence.previewStore() {
        PaddyListView(store: store).modelContainer(store.container)
    } else { Text("プレビューを作成できませんでした") }
}
