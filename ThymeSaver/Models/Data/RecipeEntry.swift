import Foundation
import GRDB

struct RecipeEntry: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable {
    var recipeEntryId: Int
    var recipeSectionId: Int
    var recipeId: Int
    var itemId: Int
    var itemPrepId: Int? = nil
    var amount: Amount
    
    var id: Int { recipeEntryId }
    
    enum Columns {
        static let recipeEntryId = Column(CodingKeys.recipeSectionId)
        static let recipeSectionId = Column(CodingKeys.recipeSectionId)
        static let recipeId = Column(CodingKeys.recipeId)
        static let itemId = Column(CodingKeys.itemId)
        static let itemPrepId = Column(CodingKeys.itemPrepId)
        static let amount = Column("Amount")
    }
    
    static var databaseTableName: String = "RecipeEntries"
}

struct RecipeEntryInsert: Codable, FetchableRecord, PersistableRecord {
    var recipeSectionId: Int
    var recipeId: Int
    var itemId: Int
    var itemPrepId: Int? = nil
    var amount: Amount
    
    static var databaseTableName: String { RecipeEntry.databaseTableName }
}
