import SwiftData

enum WIMMSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AccountGroup.self, Account.self, Category.self, Transaction.self]
    }
}

enum WIMMSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = .init(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [AccountGroup.self, Account.self, Category.self, Transaction.self]
    }
}

enum WIMMMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [WIMMSchemaV1.self, WIMMSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: WIMMSchemaV1.self, toVersion: WIMMSchemaV2.self)
        ]
    }
}
