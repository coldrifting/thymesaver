import Foundation
import GRDB
import os.log

final class AppDatabase: Sendable {
    var reader: any GRDB.DatabaseReader {
        dbWriter
    }
    
    let dbWriter: any DatabaseWriter

    init(_ dbWriter: any GRDB.DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    static let shared = makeShared()
    
    private static func makeShared() -> AppDatabase {
        do {
            // Create the "Application Support/Database" directory if needed
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Open or create the database
            let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
            let config = AppDatabase.makeConfiguration()
            let dbPool = try DatabasePool(path: databaseURL.path, configuration: config)
            
            // Create the AppDatabase
            let appDatabase = try AppDatabase(dbPool)
            
            // Populate the database if it is empty, for better demo purpose.
            try appDatabase.reset()
            
            return appDatabase
        } catch {
            fatalError("Unresolved error \(error)")
        }
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("v1") { db in
            try self.SetupDatabaseSchema(db)
        }
        
        return migrator
    }
    
    static func makeConfiguration() -> Configuration {
        var config = Configuration()
        
// Uncomment to enable SQL Logging
#if DEBUG
        config.publicStatementArguments = true
        config.prepareDatabase { db in
            db.trace {
                print("SQL: \($0)")
            }
        }
#endif
        
        return config
    }
}
