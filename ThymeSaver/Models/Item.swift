import GRDB

struct Item: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    var id: Int { itemId }
}

struct ItemInsert: Codable, FetchableRecord, PersistableRecord {
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    static var databaseTableName: String { Aisle.databaseTableName }
}

extension AppDatabase {
    func addItem(itemName: String, itemTemp: ItemTemp, defaultUnits: UnitType) throws {
        try dbWriter.write { db in
            let item = ItemInsert(itemName: itemName, itemTemp: itemTemp, defaultUnits: defaultUnits)
            try item.insert(db)
        }
    }
}
