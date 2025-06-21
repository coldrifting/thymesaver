import GRDB

struct Config: Codable, FetchableRecord, PersistableRecord, CreateTable {
    private var id = 1 // Ensure Single Row
    
    var selectedStore: Int
    
    init(selectedStore: Int) {
        self.selectedStore = selectedStore
    }
    
    static func find(_ db: Database) throws -> Config {
        try fetchOne(db)!
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: Config.databaseTableName) { t in
            t.primaryKey("id", .integer, onConflict: .replace).check { $0 == 1 }
            t.column("selectedStore", .integer).notNull()
                .references(Store.databaseTableName, onDelete: .restrict)
        }
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
