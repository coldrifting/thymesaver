import Foundation
import GRDB

extension AppDatabase {
    func SetupDatabaseSchema(_ db: Database) throws {
        try db.create(table: "store") { t in
            t.autoIncrementedPrimaryKey("storeId").notNull()
            t.column("storeName", .text).notNull()
        }
        try db.create(table: "config") { t in
            t.primaryKey("id", .integer, onConflict: .replace).check { $0 == 1 }
            t.column("selectedStore", .integer).notNull()
            
            t.foreignKey(["selectedStore"], references: "store")
        }
        try db.create(table: "aisle") { t in
            t.autoIncrementedPrimaryKey("aisleId").notNull()
            t.column("storeId", .integer).notNull()
            t.column("aisleName", .text).notNull()
            t.column("aisleOrder", .integer).notNull()
            
            t.foreignKey(["storeId"], references: "store")
        }
        try db.create(table: "item") { t in
            t.autoIncrementedPrimaryKey("itemId").notNull()
            t.column("itemName", .text).notNull()
            t.column("itemTemp", .text).notNull()
            t.column("defaultUnits", .text).notNull()
        }
    }
    
    func reset() throws {
        try dbWriter.write { db in
            try Config.deleteAll(db)
            try Item.deleteAll(db)
            try Aisle.deleteAll(db)
            try Store.deleteAll(db)
            
            try decode(for: Store.self, db: db)
            try decode(for: Aisle.self, db: db)
            try decode(for: Item.self, db: db)
            
            let config: Config = Config(selectedStore: 0)
            try config.insert(db)
        }
    }
    
    func decode<T: PersistableRecord & Codable>(for: T.Type, db: Database) throws {
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

