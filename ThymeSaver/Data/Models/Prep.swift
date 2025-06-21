import Foundation
import GRDB

struct Prep: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable, CustomStringConvertible, CreateTable, Comparable {
    static func < (lhs: Prep, rhs: Prep) -> Bool {
        return lhs.description < rhs.description
    }
    
    var prepId: Int
    var prepName: String
    
    var id: Int { prepId }
    var description: String { prepName }
    
    enum Columns {
        static let prepId = Column(CodingKeys.prepId)
        static let prepName = Column(CodingKeys.prepName)
    }
    
    static var databaseTableName: String = "Preps"
    
    init() {
        self.prepId = 0
        self.prepName = "(None)"
    }
    
    init(prepId: Int, prepName: String) {
        self.prepId = prepId
        self.prepName = prepName
    }
    
    static func createTable(_ db: Database) throws {
        try db.create(table: Prep.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("prepId")
            t.column("prepName", .text).notNull()
        }
    }
    
    static func get(itemId: Int) -> SQLRequest<Prep> {
        """
        SELECT 
            Preps.prepId, 
            Preps.prepName 
        FROM Preps
        NATURAL JOIN ItemPreps
        WHERE ItemPreps.itemId = \(itemId)
        ORDER BY LOWER(Preps.prepName);
        """
    }
}

struct PrepInsert: Codable, FetchableRecord, PersistableRecord {
    var prepName: String
    
    static var databaseTableName: String { Prep.databaseTableName }
}

extension AppDatabase {
    func addPrep(prepName: String) {
        try? dbWriter.write { db in
            let prep = PrepInsert(prepName: prepName)
            _ = try prep.insert(db)
        }
    }
    
    func renamePrep(prepId: Int, prepName: String) {
        try? dbWriter.write { db in
            var prep = try Prep.find(db, key: prepId)
            prep.prepName = prepName
            try prep.update(db, columns: [Prep.Columns.prepName])
        }
    }
    
    func deletePrep(prepId: Int) {
        try? dbWriter.write { db in
            let prep = try Prep.find(db, key: prepId)
            try prep.delete(db)
        }
    }
}
