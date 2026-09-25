import SwiftUI

struct AppRootView: View {
    @State private var store: DenStore?
    @State private var startupError: String?

    var body: some View {
        Group {
            if let store {
                PaddyListView(store: store)
                    .modelContainer(store.container)
            } else if let startupError {
                ContentUnavailableView {
                    Label("保存データを開けません", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text(startupError)
                } actions: {
                    Button("再試行", action: load)
                }
            } else {
                ProgressView("田んぼを開いています")
            }
        }
        .tint(.green)
        .task { if store == nil { load() } }
    }

    private func load() {
        do {
            var url: URL?
            #if DEBUG
            // UI tests use a separate persistent store, including across relaunches.
            if let name = ProcessInfo.processInfo.environment["NEWDEN_TEST_STORE"] {
                url = URL.documentsDirectory.appending(path: "test-\(name).store")
            }
            #endif
            store = DenStore(container: try Persistence.makeContainer(url: url))
            startupError = nil
        } catch { startupError = error.localizedDescription }
    }
}
