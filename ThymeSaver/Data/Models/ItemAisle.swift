import GRDB

struct ItemAisle: Codable, Identifiable, FetchableRecord, PersistableRecord, CreateTable {
    var itemId: Int
    var aisleId: Int
    var storeId: Int
    var bay: BayType = BayType.middle
    
    // Composite Primary Key
    var id: Int { itemId.concat(storeId) }
    
    enum Columns {
        static let itemId = Column(CodingKeys.itemId)
        static let aisleId = Column(CodingKeys.aisleId)
        static let storeId = Column(CodingKeys.storeId)
        static let bay = Column(CodingKeys.bay)
    }
    
    static var databaseTableName: String = "ItemAisles"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: ItemAisle.databaseTableName) { t in
            t.column("itemId", .integer).notNull()
                .references(Item.databaseTableName, onDelete: .cascade)
            t.column("storeId", .integer).notNull()
                .references(Store.databaseTableName, onDelete: .cascade)
            t.column("aisleId", .integer).notNull()
                .references(Aisle.databaseTableName, onDelete: .cascade)
            t.column("bay", .text).notNull()
            
            t.primaryKey(["itemId", "storeId"])
        }
    }
    
    static func getItemAisles(_ db: Database, itemId: Int) throws -> [ItemAisle] {
        let storeId = try Config.find(db).selectedStore
        return try ItemAisle.filter{itemId == $0.itemId && storeId == $0.storeId}.fetchAll(db)
    }
    
}

extension AppDatabase {
    func addItemAisle(itemId: Int, aisleId: Int, storeId: Int, bay: BayType = BayType.middle) {
        try? dbWriter.write { db in
            let itemAisle = ItemAisle(itemId: itemId, aisleId: aisleId, storeId: storeId, bay: bay)
            try itemAisle.insert(db)
        }
    }
    
    func deleteItemAisle(itemId: Int, storeId: Int) {
        try? dbWriter.write { db in
            _ = try ItemAisle.deleteAll(db, keys: [itemId, storeId])
        }
    }
    
    func updateItemAisle(itemId: Int, storeId: Int, aisleId: Int) {
        try? dbWriter.write { db in
            let compositeKey = [
                ItemAisle.Columns.itemId.name: itemId,
                ItemAisle.Columns.storeId.name: storeId
            ]
            
            let bay: BayType? = try? ItemAisle.find(db, key: compositeKey).bay
            
            let itemAisleEntry = ItemAisle(itemId: itemId, aisleId: aisleId, storeId: storeId, bay: bay ?? .middle)
            try? itemAisleEntry.upsert(db)
        }
    }
    
    func updateItemAisleBay(itemId: Int, storeId: Int, newBay: BayType) {
        try? dbWriter.write { db in
            let compositeKey = [
                ItemAisle.Columns.itemId.name: itemId,
                ItemAisle.Columns.storeId.name: storeId
            ]
            
            var itemAisle = try ItemAisle.find(db, key: compositeKey)
            itemAisle.bay = newBay
            try itemAisle.update(db, columns: [ItemAisle.Columns.bay])
        }
    }
}
