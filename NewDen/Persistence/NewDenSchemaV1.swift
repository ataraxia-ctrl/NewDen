import SwiftData

enum NewDenSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [Paddy.self, Den.self, Slot.self, Content.self] }
}

typealias Paddy = NewDenSchemaV1.Paddy
typealias Den = NewDenSchemaV1.Den
typealias Slot = NewDenSchemaV1.Slot
typealias Content = NewDenSchemaV1.Content
