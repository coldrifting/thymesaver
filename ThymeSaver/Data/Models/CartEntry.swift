import GRDB

struct CartEntry: Codable, Identifiable, FetchableRecord, PersistableRecord, CustomStringConvertible, CreateTable, Hashable, Comparable {
    var cartEntryId: Int
    
    var itemName: String
    var itemTemp: ItemTemp = ItemTemp.ambient
    var itemAmount: Amount
    
    var aisleId: Int
    var aisleName: String
    var aisleOrder: Int
    var bay: BayType
    
    var checked: Bool = false
    
    var id: Int { cartEntryId }
    var description: String { itemName }
    
    static func < (lhs: CartEntry, rhs: CartEntry) -> Bool {
        if (lhs.aisleOrder == rhs.aisleOrder) {
            if (lhs.itemTemp == rhs.itemTemp) {
                return lhs.itemName < rhs.itemName
            }
            return lhs.itemTemp < rhs.itemTemp
        }
        return lhs.aisleOrder < rhs.aisleOrder
    }
    
    enum Columns {
        static let cartEntryId = Column(CodingKeys.cartEntryId)
        
        static let itemName = Column(CodingKeys.itemName)
        static let itemTemp = Column(CodingKeys.itemTemp)
        static let itemAmount = Column(CodingKeys.itemAmount)
        
        static let aisleId = Column(CodingKeys.aisleId)
        static let aisleName = Column(CodingKeys.aisleName)
        static let aisleOrder = Column(CodingKeys.aisleOrder)
        
        static let checked = Column(CodingKeys.checked)
    }
    
    static var databaseTableName: String = "CartEntries"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: CartEntry.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("cartEntryId")
            
            t.column("itemName", .text).notNull()
            t.column("itemTemp", .text).notNull()
            t.column("itemAmount", .text).notNull()
            
            t.column("aisleId", .integer).notNull()
            t.column("aisleName", .text).notNull()
            t.column("aisleOrder", .integer).notNull()
            t.column("bay", .text).notNull()
            
            t.column("checked", .boolean).notNull()
        }
    }
}

struct CartEntryInsert: Codable, FetchableRecord, PersistableRecord {
    var itemName: String
    var itemTemp: ItemTemp = ItemTemp.ambient
    var itemAmount: Amount
    
    var aisleId: Int
    var aisleName: String
    var aisleOrder: Int
    var bay: BayType
    
    var checked: Bool = false
    
    enum Columns {
        static let itemName = Column(CodingKeys.itemName)
        static let itemTemp = Column(CodingKeys.itemTemp)
        static let itemAmount = Column(CodingKeys.itemAmount)
        
        static let aisleId = Column(CodingKeys.aisleId)
        static let aisleName = Column(CodingKeys.aisleName)
        static let aisleOrder = Column(CodingKeys.aisleOrder)
        static let bay = Column(CodingKeys.bay)
        
        static let checked = Column(CodingKeys.checked)
    }
    
    static var databaseTableName: String = CartEntry.databaseTableName
}

extension AppDatabase {
    func generateCart() -> Void {
        try? dbWriter.write { db in
            try CartEntry.deleteAll(db)
            
            let cartData = CartData.combine(cartData: (try? CartData.all(db).fetchAll(db)) ?? [])
            
            for data in cartData {
                let entry = CartEntryInsert(
                    itemName: data.itemName,
                    itemAmount: data.amount,
                    aisleId: data.aisleId ?? -1,
                    aisleName: data.aisleName ?? "Not Found",
                    aisleOrder: data.aisleOrder ?? -1,
                    bay: data.bay ?? BayType.middle
                )
                
                try entry.insert(db)
            }
        }
    }
    
    func toggleCartEntryChecked(entryId: Int) -> Void {
        try? dbWriter.write { db in
            var entry = try CartEntry.fetchOne(db, key: entryId)!
            entry.checked = !entry.checked
            try entry.update(db, columns: [CartEntry.Columns.checked])
        }
    }
}
