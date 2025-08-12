import Foundation
import GRDB
import os.log

protocol CreateTable {
    static func createTable(_ db: Database) throws -> Void
}

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
    
    typealias DatabaseSeed = PersistableRecord & Codable & CreateTable
    
    let databaseTypes: Array<any DatabaseSeed.Type> = [
        Store.self,
        Aisle.self,
        Item.self,
        ItemAisle.self,
        Prep.self,
        ItemPrep.self,
        Recipe.self,
        RecipeSection.self,
        RecipeEntry.self,
        RecipeStep.self
    ]
    
    static func makeConfiguration() -> Configuration {
        var config = Configuration()
        
// Uncomment to enable SQL Logging
#if DEBUG && true
        config.publicStatementArguments = true
        config.prepareDatabase { db in
            db.trace {
                print("SQL: \($0)")
            }
        }
#endif
        
        return config
    }
    
    func SetupDatabaseSchema(_ db: Database) throws {
        for type in databaseTypes {
            try type.createTable(db)
        }
        
        try CartEntry.createTable(db)
        
        try Config.createTable(db)
    }
    
    func reset() throws {
        try dbWriter.write { db in
            try Config.deleteAll(db)
            
            for type in databaseTypes.reversed() {
                try type.deleteAll(db)
            }
            
            for type in databaseTypes {
                try decode(db, for: type)
            }
            
            let config: Config = Config(selectedStore: 1)
            try config.insert(db)
        }
    }
    
    func decode<T: PersistableRecord & Codable>(_ db: Database, for: T.Type) throws {
        let jsonFileName = "\(T.self)".last == "y"
        ? (try? "\(T.self)".replacing(Regex("y$"), with: "ies")) ?? "\(T.self)s"
        : "\(T.self)s"
        
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            fatalError("Failed to find \(jsonFileName).json")
        }
        
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([T].self, from: data)
        
        for item in decoded {
            try item.insert(db)
        }
    }
}
