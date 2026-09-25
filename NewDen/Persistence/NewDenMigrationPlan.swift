import SwiftData

enum NewDenMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [NewDenSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
