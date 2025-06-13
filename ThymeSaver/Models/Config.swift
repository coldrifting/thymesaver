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
