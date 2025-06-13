import GRDB

struct Aisle: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var aisleId: Int
    var storeId: Int
    var aisleName: String
    var aisleOrder: Int
    
    var id: Int { aisleId }
}

struct AisleInsert: Codable, FetchableRecord, PersistableRecord {
    var storeId: Int
    var aisleName: String
    var aisleOrder: Int
    
    static var databaseTableName: String { Aisle.databaseTableName }
}

extension AppDatabase {
    func addAisle(aisleName: String, storeId: Int) throws {
        try dbWriter.write { db in
            let aisle = AisleInsert(storeId: storeId, aisleName: aisleName, aisleOrder: -1)
            try aisle.insert(db)
        }
    }
}
