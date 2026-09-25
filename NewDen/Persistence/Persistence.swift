import Foundation
import SwiftData

@MainActor
enum Persistence {
    static func makeContainer(inMemory: Bool = false, url: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: NewDenSchemaV1.self)
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, migrationPlan: NewDenMigrationPlan.self, configurations: [configuration])
    }

    static func previewStore() throws -> DenStore {
        let store = DenStore(container: try makeContainer(inMemory: true))
        let den = try store.createPaddy(kind: .goal)
        try store.write(den: den, position: 0, text: "心地よい毎日をつくる")
        try store.write(den: den, position: 1, text: "朝、ゆっくりお茶を飲む")
        store.undoManager.removeAllActions()
        store.refreshUndoState()
        return store
    }
}
