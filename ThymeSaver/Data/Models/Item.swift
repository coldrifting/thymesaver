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
    func getItems(filter: String = "") throws -> [(item: Item, referencees: [String])] {
        try dbWriter.write { db in
            let items: [Item] = try Item.getItems(db, filter: filter)
            
            let recipeEntries: [RecipeEntry] = try RecipeEntry.fetchAll(db)
            
            return items.map { item in
                (item: item, recipeEntries.contains(where: { $0.itemId == item.itemId }) ? ["referenced"] : [""])
            }
        }
    }
    
    func addItem(
        itemName: String
    ) {
        addItem(itemName: itemName, itemTemp: .ambient, defaultUnits: .count)
    }
    
    func addItem(
        itemName: String,
        itemTemp: ItemTemp,
        defaultUnits: UnitType
    ) {
        try? dbWriter.write { db in
            let item = ItemInsert(itemName: itemName, itemTemp: itemTemp, defaultUnits: defaultUnits)
            try item.insert(db)
        }
    }
    
    func deleteItem(itemId: Int) {
        try? dbWriter.write { db in
            _ = try Item.deleteOne(db, key: itemId)
        }
    }
    
    func renameItem(itemId: Int, newName: String) {
        try? dbWriter.write { db in
            var item = try Item.find(db, key: itemId)
            item.itemName = newName
            try item.update(db, columns: [Item.Columns.itemName])
        }
    }
    
    func updateItemTemp(itemId: Int, itemTemp: ItemTemp) {
        try? dbWriter.write { db in
            var item = try Item.find(db, key: itemId)
            item.itemTemp = itemTemp
            try item.update(db, columns: [Item.Columns.itemTemp])
        }
    }
    
    func updateItemDefaultUnits(itemId: Int, defaultUnits: UnitType) {
        try? dbWriter.write { db in
            var item = try Item.find(db, key: itemId)
            item.defaultUnits = defaultUnits
            try item.update(db, columns: [Item.Columns.defaultUnits])
        }
    }
}
