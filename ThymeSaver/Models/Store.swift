import GRDB

struct Store: Codable, Identifiable, FetchableRecord, PersistableRecord {

    var storeId: Int
    var storeName: String
    
    var id: Int { storeId }
    
    enum Columns {
        static let storeName = Column(CodingKeys.storeName)
    }
}

struct StoreInsert: Codable, FetchableRecord, PersistableRecord {
    var storeName: String
    
    static var databaseTableName: String { Store.databaseTableName }
}
