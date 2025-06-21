import GRDB

struct ItemPrep: Codable, Identifiable, FetchableRecord, PersistableRecord, CreateTable {
    var itemId: Int
    var prepId: Int
    
    var id: Int { prepId }
    
    enum Columns {
        static let itemId = Column(CodingKeys.itemId)
        static let prepId = Column(CodingKeys.prepId)
    }
    
    static var databaseTableName: String = "ItemPreps"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: ItemPrep.databaseTableName) { t in
            t.column("itemId", .integer).notNull()
                .references(Item.databaseTableName, onDelete: .cascade)
            t.column("prepId", .integer).notNull()
                .references(Prep.databaseTableName, onDelete: .cascade)
            
            t.primaryKey(["itemId", "prepId"])
        }
    }
    
    static func getItemPreps(_ db: Database, itemId: Int) throws -> [ItemPrep] {
        return try ItemPrep
            .filter{ $0.itemId == itemId }
            .fetchAll(db)
    }
}

extension AppDatabase {
    func addItemPrep(itemId: Int, prepId: Int) {
        try? dbWriter.write { db in
            let itemPrep = ItemPrep(itemId: itemId, prepId: prepId)
            try itemPrep.upsert(db)
        }
    }
    
    func deleteItemPrep(itemId: Int, prepId: Int) {
        try? dbWriter.write { db in
            let key: [String:Int] = ["itemId": itemId, "prepId": prepId]
            _ = try ItemPrep.deleteOne(db, key: key)
        }
    }
}
