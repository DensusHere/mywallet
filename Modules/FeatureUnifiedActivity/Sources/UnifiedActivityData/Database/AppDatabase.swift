// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DelegatedSelfCustodyDomain
import Foundation
import GRDB

protocol AppDatabaseAPI {

    var databaseReader: DatabaseReader { get }
    func deleteAllActivityEntities() throws
    func saveActivityEntities(_ activities: [ActivityEntity]) throws
    func applyDBUpdate(_ update: ActivityDBUpdate) throws
}

enum DatabaseColumn: String {
    case identifier
    case json
    case networkIdentifier
    case pubKey
    case state
    case timestamp
}

struct AppDatabase: AppDatabaseAPI {
    /// Creates an `AppDatabase`, and make sure the database schema is ready.
    init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    private let dbWriter: any DatabaseWriter

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = true

        migrator.registerMigration("activityEntity") { db in
            // Create a table
            // See https://github.com/groue/GRDB.swift#create-tables
            try db.create(table: "activityEntity") { t in
                t.primaryKey([
                    DatabaseColumn.identifier.rawValue,
                    DatabaseColumn.networkIdentifier.rawValue
                ])

                t.column(DatabaseColumn.identifier.rawValue, .text).notNull()
                t.column(DatabaseColumn.json.rawValue, .text).notNull()
                t.column(DatabaseColumn.networkIdentifier.rawValue, .text).notNull()
                t.column(DatabaseColumn.pubKey.rawValue, .text).notNull()
                t.column(DatabaseColumn.state.rawValue, .text).notNull()
                t.column(DatabaseColumn.timestamp.rawValue, .date).notNull()
            }
        }
        return migrator
    }
}

// MARK: - Database Access: Writes

extension AppDatabase {

    /// Saves (inserts or updates) a ActivityEntity. When the method returns, the
    /// ActivityEntity is present in the database, and its id is not nil.
    func saveActivityEntity(_ activity: ActivityEntity) throws {
        try dbWriter.write { db in
            try activity.save(db)
        }
    }

    /// Saves (inserts or updates) a ActivityEntity. When the method returns, the
    /// ActivityEntity is present in the database, and its id is not nil.
    func saveActivityEntities(_ activities: [ActivityEntity]) throws {
        guard activities.isNotEmpty else {
            return
        }
        try dbWriter.write { db in
            for activity in activities {
                try activity.save(db)
            }
        }
    }

    /// Delete all ActivityEntities
    func applyDBUpdate(_ update: ActivityDBUpdate) throws {
        try dbWriter.write { db in
            if update.updateType == .snapshot {
                try ActivityEntity
                    .filter(
                        Column(DatabaseColumn.pubKey.rawValue) == update.pubKey
                          && Column(DatabaseColumn.networkIdentifier.rawValue) == update.network
                    )
                    .deleteAll(db)
            }
            guard update.entries.isNotEmpty else {
                return
            }
            for entry in update.entries {
                try entry.save(db)
            }
        }
    }

    /// Delete all ActivityEntities
    func deleteAllActivityEntities() throws {
        try dbWriter.write { db in
            _ = try ActivityEntity.deleteAll(db)
        }
    }
}

extension AppDatabase {
    /// Provides a read-only access to the database
    var databaseReader: DatabaseReader {
        dbWriter
    }
}
