import GRDB

struct Item: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    var id: Int { itemId }
    
    enum Columns {
        static let itemId = Column(CodingKeys.itemId)
        static let itemName = Column(CodingKeys.itemName)
        static let itemTemp = Column(CodingKeys.itemTemp)
        static let defaultUnits = Column(CodingKeys.defaultUnits)
    }
    
    static var databaseTableName: String = "Items"
    
    static func getItems(_ db: Database, filter: String = "") throws -> [Item] {
        if (filter.trim().isEmpty) {
            return try Item.order(Item.Columns.itemName.asc).fetchAll(db)
        }
        
        let filterString = filter.lowercased().trim()
        
        return try Item
            .filter(Item.Columns.itemName.like("%\(filterString)%"))
            .order(Item.Columns.itemName.asc)
            .fetchAll(db)
    }
}

struct ItemInsert: Codable, FetchableRecord, PersistableRecord {
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    static var databaseTableName: String { Item.databaseTableName }
}

extension AppDatabase {
    func addItem(
        itemName: String,
        itemTemp: ItemTemp = ItemTemp.ambient,
        defaultUnits: UnitType = UnitType.count
    ) throws {
        try dbWriter.write { db in
            let item = ItemInsert(itemName: itemName, itemTemp: itemTemp, defaultUnits: defaultUnits)
            try item.insert(db)
        }
    }
    
    func deleteItem(itemId: Int) throws {
        try dbWriter.write { db in
            _ = try Item.deleteOne(db, key: itemId)
        }
    }
    
    func renameItem(itemId: Int, newName: String) throws {
        try dbWriter.write { db in
            var item = try Item.find(db, key: itemId)
            item.itemName = newName
            try item.update(db, columns: [Item.Columns.itemName])
        }
    }
}
