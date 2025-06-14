import GRDB

struct ItemAisle: Codable, Identifiable, FetchableRecord, PersistableRecord {
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
}

extension AppDatabase {
    func getItemAisles(storeId: Int, itemId: Int) throws -> [ItemAisle] {
        try dbWriter.write { db in
            let itemAisles = try ItemAisle.filter{itemId == $0.itemId && storeId == $0.storeId}.fetchAll(db)
            return itemAisles
        }
    }
    
    func addItemAisle(itemId: Int, aisleId: Int, storeId: Int, bay: BayType = BayType.middle) throws {
        try dbWriter.write { db in
            let itemAisle = ItemAisle(itemId: itemId, aisleId: aisleId, storeId: storeId, bay: bay)
            try itemAisle.insert(db)
        }
    }
    
    func deleteItemAisle(itemId: Int, storeId: Int) throws {
        try dbWriter.write { db in
            _ = try ItemAisle.deleteAll(db, keys: [itemId, storeId])
        }
    }
    
    func updateItemAisleBay(itemId: Int, storeId: Int, newBay: BayType) throws {
        try dbWriter.write { db in
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
