import Foundation
import GRDB
import os.log

final class AppDatabase: Sendable {
    private let dbWriter: any DatabaseWriter

    init(_ dbWriter: any GRDB.DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
        
        migrator.registerMigration("v1") { db in
            try db.create(table: "store") { t in
                t.autoIncrementedPrimaryKey("storeId").notNull()
                t.column("storeName", .text).notNull()
            }
            try db.create(table: "config") { t in
                t.primaryKey("id", .integer, onConflict: .replace).check { $0 == 1 }
                t.column("selectedStore", .integer).notNull()
                
                t.foreignKey(["selectedStore"], references: "store")
            }
        }
        
        return migrator
    }
}


// MARK: - Database Access: Writes
// The write methods execute invariant-preserving database transactions.
// In this demo repository, they are pretty simple.

extension AppDatabase {
    func selectStore(storeId: Int) throws {
        try dbWriter.write { db in
            let config: Config = Config(selectedStore: storeId)
            try config.update(db)
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
            try Config.deleteAll(db)
            try Store.deleteAll(db)
            
            guard let storesURL = Bundle.main.url(forResource: "Stores", withExtension: "json") else {
                fatalError("Failed to find Stores.json")
            }
            
            let storesData = try Data(contentsOf: storesURL)
            let stores = try JSONDecoder().decode([Store].self, from: storesData)
            
            for store in stores {
                try store.insert(db)
            }
            
            let config: Config = Config(selectedStore: 0)
            try config.insert(db)
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
