import Foundation
import GRDB

struct Store: Codable, Identifiable, FetchableRecord, PersistableRecord {
    var storeId: Int
    var storeName: String
    
    var id: Int { storeId }
}

struct StoreInsert: Codable, FetchableRecord, PersistableRecord {
    var storeName: String
    
    static var databaseTableName: String { Store.databaseTableName }
}

extension AppDatabase {
    func selectStore(storeId: Int) throws {
        try dbWriter.write { db in
            let config: Config = Config(selectedStore: storeId)
            try config.update(db)
        }
    }
    
    func addStore(storeName: String) throws {
        try dbWriter.write { db in
            let store = StoreInsert(storeName: storeName)
            try store.insert(db)
        }
    }
    
    func deleteStore(storeId: Int) throws {
        try dbWriter.write { db in
            let store = Store(storeId: storeId, storeName: "")
            try store.delete(db)
        }
    }
    
    func renameStore(storeId: Int, newName: String) throws {
        try dbWriter.write { db in
            let store = Store(storeId: storeId, storeName: newName)
            try store.update(db)
        }
    }
    
    func getStore(storeId: Int) throws -> Store {
        try dbWriter.write { db in
            let store = try Store.fetchOne(db, key: storeId)!
            return store
        }
    }
}
