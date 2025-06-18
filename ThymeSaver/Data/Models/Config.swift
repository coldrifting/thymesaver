import GRDB

struct Config: Codable, FetchableRecord, PersistableRecord {
    private var id = 1 // Ensure Single Row
    
    var selectedStore: Int
    
    init(selectedStore: Int) {
        self.selectedStore = selectedStore
    }
    
    static func find(_ db: Database) throws -> Config {
        try fetchOne(db)!
    }
}

extension AppDatabase {
    func getSelectedStoreId() throws -> Int {
        try dbWriter.read { db in
            try Config.find(db).selectedStore
        }
    }
    
    func selectStore(storeId: Int) {
        try? dbWriter.write { db in
            let config: Config = Config(selectedStore: storeId)
            try config.update(db)
        }
    }
}
