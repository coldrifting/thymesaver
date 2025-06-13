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
            let x = StoreInsert(storeName: storeName)
            try x.insert(db)
        }
    }
    
    func deleteStore(storeId: Int) throws {
        try dbWriter.write { db in
            let x = Store(storeId: storeId, storeName: "")
            try x.delete(db)
        }
    }
    
    func renameStore(storeId: Int, newName: String) throws {
        try dbWriter.write { db in
            let x = Store(storeId: storeId, storeName: newName)
            try x.update(db)
        }
    }
}
