import GRDB

struct Aisle: Codable, Identifiable, FetchableRecord, PersistableRecord, CustomStringConvertible {
    var aisleId: Int
    var storeId: Int
    var aisleName: String
    var aisleOrder: Int = -1
    
    var id: Int { aisleId }
    var description: String { aisleName }
    
    enum Columns {
        static let aisleId = Column(CodingKeys.aisleId)
        static let storeId = Column(CodingKeys.storeId)
        static let aisleName = Column(CodingKeys.aisleName)
        static let aisleOrder = Column(CodingKeys.aisleOrder)
    }
    
    static var databaseTableName: String = "Aisles"
    
    static func getAisles(_ db: Database) throws -> [Aisle] {
        let storeIdChecked = (try? Config.find(db).selectedStore) ?? -1
        return try Aisle
            .filter{ $0.storeId == storeIdChecked }
            .order(\.aisleOrder.asc)
            .fetchAll(db)
    }
}

struct AisleInsert: Codable, FetchableRecord, PersistableRecord {
    var storeId: Int
    var aisleName: String
    var aisleOrder: Int = -1
    
    static var databaseTableName: String { Aisle.databaseTableName }
}

extension AppDatabase {
    func getAisle(aisleId: Int) throws -> Aisle {
        try dbWriter.write { db in
            let aisle = try Aisle.fetchOne(db, key: aisleId)!
            return aisle
        }
    }
    
    func addAisle(aisleName: String, storeId: Int, aisleOrder: Int = Int.max) {
        try? dbWriter.write { db in
            let aisle = AisleInsert(storeId: storeId, aisleName: aisleName, aisleOrder: aisleOrder)
            try aisle.insert(db)
            try syncAisleOrder(db: db)
        }
    }
    
    func renameAisle(aisleId: Int, newName: String) {
        try? dbWriter.write { db in
            var aisle = try Aisle.find(db, key: aisleId)
            aisle.aisleName = newName
            try aisle.update(db, columns: [Aisle.Columns.aisleName])
        }
    }
    
    func deleteAisle(aisleId: Int, storeId: Int) {
        try? dbWriter.write { db in
            try Aisle.deleteOne(db, key: aisleId)
            try syncAisleOrder(db: db)
        }
    }
    
    func moveAisle(aisleId: Int, newIndex: Int) {
        try? dbWriter.write { db in
            if var aisle: Aisle = try? Aisle.find(db, key: aisleId) {
                aisle.aisleOrder = newIndex
                try aisle.update(db)
            }
        }
    }
    
    func syncAisleOrder(db: Database) throws {
        let aisles = try Aisle.getAisles(db)
        for (index, aisle) in aisles.enumerated() {
            let aisleCopy = Aisle(
                aisleId: aisle.aisleId,
                storeId: aisle.storeId,
                aisleName: aisle.aisleName,
                aisleOrder: index
            )
            try aisleCopy.update(db)
        }
    }
}
