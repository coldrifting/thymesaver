import Foundation
import GRDB
import os.log

/// The type that provides access to the application database.
///
/// For example:
///
/// ```swift
/// // Create an empty, in-memory, AppDatabase
/// let config = AppDatabase.makeConfiguration()
/// let dbQueue = try DatabaseQueue(configuration: config)
/// let appDatabase = try AppDatabase(dbQueue)
/// ```
final class AppDatabase: Sendable {
    /// Access to the database.
    ///
    /// See <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseconnections>
    private let dbWriter: any DatabaseWriter
    
    /// Creates a `AppDatabase`, and makes sure the database schema
    /// is ready.
    ///
    /// - important: Create the `DatabaseWriter` with a configuration
    ///   returned by ``makeConfiguration(_:)``.
    init(_ dbWriter: any GRDB.DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    /// The DatabaseMigrator that defines the database schema.
    ///
    /// See <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations>
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        // Speed up development by nuking the database when migrations change
        // See <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/migrations#The-eraseDatabaseOnSchemaChange-Option>
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("v1") { db in
            // Create a table
            // See <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/databaseschema>
            // TODO - Merge with other table def
            try db.create(table: "store") { t in
                t.autoIncrementedPrimaryKey("storeId").notNull()
                t.column("storeName", .text).notNull()
            }
        }
        
        // Migrations for future application versions will be inserted here:
        // migrator.registerMigration(...) { db in
        //     ...
        // }
        
        return migrator
    }
}

// MARK: - Database Configuration

extension AppDatabase {
    // Uncomment for enabling SQL logging
    private static let sqlLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "SQL")
    
    /// Returns a database configuration suited for `AppDatabase`.
    ///
    /// - parameter config: A base configuration.
    static func makeConfiguration(_ config: Configuration = Configuration()) -> Configuration {
        // var config = config
        //
        // Add custom SQL functions or collations, if needed:
        // config.prepareDatabase { db in
        //     db.add(function: ...)
        // }
        //
        // Uncomment for enabling SQL logging if the `SQL_TRACE` environment variable is set.
        // See <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/database/trace(options:_:)>
        // if ProcessInfo.processInfo.environment["SQL_TRACE"] != nil {
        //     config.prepareDatabase { db in
        //         let dbName = db.description
        //         db.trace { event in
        //             // Sensitive information (statement arguments) is not
        //             // logged unless config.publicStatementArguments is set
        //             // (see below).
        //             sqlLogger.debug("\(dbName): \(event)")
        //         }
        //     }
        // }
        //
        // #if DEBUG
        // // Protect sensitive information by enabling verbose debugging in
        // // DEBUG builds only.
        // // See <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/configuration/publicstatementarguments>
        // config.publicStatementArguments = true
        // #endif
        
        return config
    }
}

// MARK: - Database Access: Writes
// The write methods execute invariant-preserving database transactions.
// In this demo repository, they are pretty simple.

extension AppDatabase {
    func createStores() throws {
        try dbWriter.write { db in
            let x = Store(storeId: 0, storeName: "Test")
            try x.save(db)
        }
    }
    
    func addStore(storeName: String) throws {
        try dbWriter.write { db in
            let x = StoreInsert(storeName: storeName)
            try x.insert(db)
        }
    }
    
    func deleteStore(storeId: Int) throws {
        try dbWriter.write { db in
            let x = Store(storeId: storeId, storeName: "")
            try x.delete(db)
        }
    }
    
    func renameStore(storeId: Int, newName: String) throws {
        try dbWriter.write { db in
            let x = Store(storeId: storeId, storeName: newName)
            try x.update(db)
        }
    }
    
    func resetStores() throws {
        try dbWriter.write { db in
            try Store.deleteAll(db)
            
            guard let storesURL = Bundle.main.url(forResource: "Stores", withExtension: "json") else {
                fatalError("Failed to find Stores.json")
            }
            
            let storesData = try Data(contentsOf: storesURL)
            let stores = try JSONDecoder().decode([Store].self, from: storesData)
            
            for store in stores {
                try store.insert(db)
            }
        }
    }
}

// MARK: - Database Access: Reads

// This demo app does not provide any specific reading method, and instead
// gives an unrestricted read-only access to the rest of the application.
// In your app, you are free to choose another path, and define focused
// reading methods.
extension AppDatabase {
    /// Provides a read-only access to the database.
    var reader: any GRDB.DatabaseReader {
        dbWriter
    }
}
