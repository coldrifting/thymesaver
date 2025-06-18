import GRDB

struct ItemPrep: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var itemPrepId: Int
    var itemId: Int
    var prepName: String
    
    var id: Int { itemPrepId }
    
    enum Columns {
        static let itemPrepId = Column(CodingKeys.itemPrepId)
        static let itemId = Column(CodingKeys.itemId)
        static let prepName = Column(CodingKeys.prepName)
    }
    
    static var databaseTableName: String = "ItemPreps"
    
    static func getItemPreps(_ db: Database, itemId: Int) throws -> [ItemPrep] {
        return try ItemPrep
            .filter{ $0.itemId == itemId }
            .order(Columns.prepName.collating(.localizedCaseInsensitiveCompare).asc)
            .fetchAll(db)
    }
}

struct ItemPrepInsert: Codable, FetchableRecord, PersistableRecord {
    var itemId: Int
    var prepName: String
    
    static var databaseTableName: String { ItemPrep.databaseTableName }
}

extension AppDatabase {
    func addItemPrep(itemId: Int, prepName: String) {
        try? dbWriter.write { db in
            let itemPrep = ItemPrepInsert(itemId: itemId, prepName: prepName)
            _ = try itemPrep.insert(db)
        }
    }
    
    func deleteItemPrep(itemPrepId: Int) {
        try? dbWriter.write { db in
            _ = try ItemPrep.deleteOne(db, key: itemPrepId)
        }
    }
    
    func renameItemPrep(itemPrepId: Int, newName: String) {
        try? dbWriter.write { db in
            var itemPrep = try ItemPrep.find(db, key: itemPrepId)
            itemPrep.prepName = newName
            try itemPrep.update(db, columns: [ItemPrep.Columns.prepName])
        }
    }
}
