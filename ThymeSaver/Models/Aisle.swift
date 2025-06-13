import GRDB

struct Aisle: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var aisleId: Int
    var storeId: Int
    var aisleName: String
    var aisleOrder: Int = -1
    
    var id: Int { aisleId }
    
    enum Columns {
        static let storeId = Column(CodingKeys.storeId)
        static let aisleOrder = Column(CodingKeys.aisleOrder)
    }
    
    static func getAisles(db: Database, storeId: Int) throws -> [Aisle] {
        return try Aisle.filter{ $0.storeId == storeId }.order(\.aisleOrder.asc).fetchAll(db)
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
    
    func addAisle(aisleName: String, storeId: Int, aisleOrder: Int = Int.max) throws {
        try dbWriter.write { db in
            let aisle = AisleInsert(storeId: storeId, aisleName: aisleName, aisleOrder: aisleOrder)
            try aisle.insert(db)
            try syncAisleOrder(db: db, storeId: storeId)
        }
    }
    
    func renameAisle(aisleId: Int, newName: String) throws {
        try dbWriter.write { db in
            if var aisle: Aisle = try? Aisle.find(db, key: aisleId) {
                aisle.aisleName = newName
                try aisle.update(db)
            }
        }
    }
    
    func deleteAisle(aisleId: Int, storeId: Int) throws {
        try dbWriter.write { db in
            let aisle = Aisle(aisleId: aisleId, storeId: -1, aisleName: "")
            try aisle.delete(db)
            try syncAisleOrder(db: db, storeId: storeId)
        }
    }
    
    func moveAisle(aisleId: Int, newIndex: Int) throws {
        try dbWriter.write { db in
            if var aisle: Aisle = try? Aisle.find(db, key: aisleId) {
                aisle.aisleOrder = newIndex
                try aisle.update(db)
            }
        }
    }
    
    func syncAisleOrder(db: Database, storeId: Int) throws {
        let aisles = try Aisle.getAisles(db: db, storeId: storeId)
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
