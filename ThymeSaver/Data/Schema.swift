import Foundation
import GRDB

extension AppDatabase {
    func SetupDatabaseSchema(_ db: Database) throws {
        try db.create(table: Store.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("storeId").notNull()
            t.column("storeName", .text).notNull()
        }
        try db.create(table: Aisle.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("aisleId").notNull()
            t.column("storeId", .integer).notNull()
            t.column("aisleName", .text).notNull()
            t.column("aisleOrder", .integer).notNull()
            
            t.foreignKey(["storeId"], references: Store.databaseTableName, onDelete: .cascade)
        }
        try db.create(table: Item.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("itemId").notNull()
            t.column("itemName", .text).notNull()
            t.column("itemTemp", .text).notNull()
            t.column("defaultUnits", .text).notNull()
        }
        try db.create(table: ItemAisle.databaseTableName) { t in
            t.column("itemId", .integer).notNull()
            t.column("storeId", .integer).notNull()
            t.column("aisleId", .integer).notNull()
            t.column("bay", .text).notNull()
            
            t.foreignKey(["itemId"], references: Item.databaseTableName, onDelete: .cascade)
            t.foreignKey(["storeId"], references: Store.databaseTableName, onDelete: .cascade)
            t.foreignKey(["aisleId"], references: Aisle.databaseTableName, onDelete: .cascade)
            
            t.primaryKey(["itemId", "storeId"])
        }
        
        try db.create(table: Config.databaseTableName) { t in
            t.primaryKey("id", .integer, onConflict: .replace).check { $0 == 1 }
            t.column("selectedStore", .integer).notNull()
            
            t.foreignKey(["selectedStore"], references: Store.databaseTableName, onDelete: .restrict)
        }
    }
    
    func reset() throws {
        try dbWriter.write { db in
            try Config.deleteAll(db)
            try ItemAisle.deleteAll(db)
            try Item.deleteAll(db)
            try Aisle.deleteAll(db)
            try Store.deleteAll(db)
            
            try decode(db, for: Store.self)
            try decode(db, for: Aisle.self)
            try decode(db, for: Item.self)
            try decode(db, for: ItemAisle.self)
            
            let config: Config = Config(selectedStore: 1)
            try config.insert(db)
        }
    }
    
    func decode<T: PersistableRecord & Codable>(_ db: Database, for: T.Type) throws {
        let jsonFileName = "\(T.self)s"
        
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

