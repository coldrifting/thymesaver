import Foundation
import GRDB

struct Store: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable {
    var storeId: Int
    var storeName: String
    
    var id: Int { storeId }
    
    enum Columns {
        static let storeId = Column(CodingKeys.storeId)
        static let storeName = Column(CodingKeys.storeName)
    }
    
    static var databaseTableName: String = "Stores"
}

struct StoreInsert: Codable, FetchableRecord, PersistableRecord {
    var storeName: String
    
    static var databaseTableName: String { Store.databaseTableName }
}

extension AppDatabase {
    func addStore(storeName: String) throws {
        try dbWriter.write { db in
            let store = StoreInsert(storeName: storeName)
            try store.insert(db)
        }
    }
    
    func deleteStore(storeId: Int) throws {
        try dbWriter.write { db in
            _ = try Store.deleteOne(db, key: storeId)
        }
    }
    
    func renameStore(storeId: Int, newName: String) throws {
        try dbWriter.write { db in
            var store = try Store.find(db, key: storeId)
            store.storeName = newName
            try store.update(db, columns: [Store.Columns.storeName])
        }
    }
    
    func getStore(storeId: Int) throws -> Store {
        try dbWriter.write { db in
            let store = try Store.fetchOne(db, key: storeId)!
            return store
        }
    }
}
