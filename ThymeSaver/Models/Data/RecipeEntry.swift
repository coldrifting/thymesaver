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
        static let amount = Column(CodingKeys.amount)
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

extension AppDatabase {
    func addRecipeEntry(recipeSectionId: Int, recipeId: Int, itemId: Int, itemPrepId: Int? = nil, amount: Amount) throws {
        try dbWriter.write { db in
            let recipeEntry = RecipeEntryInsert(
                recipeSectionId: recipeSectionId,
                recipeId: recipeId,
                itemId: itemId,
                itemPrepId: itemPrepId,
                amount: amount
            )
            _ = try recipeEntry.insert(db)
        }
    }
    
    func updateRecipeEntry(recipeEntryId: Int, itemId: Int, itemPrepId: Int? = nil, amount: Amount) throws {
        try dbWriter.write { db in
            let recipeEntry = RecipeEntry(
                recipeEntryId: recipeEntryId,
                recipeSectionId: -1,
                recipeId: -1,
                itemId: itemId,
                itemPrepId: itemPrepId,
                amount: amount
            )
            _ = try recipeEntry.update(db, columns: [RecipeEntry.Columns.itemId, RecipeEntry.Columns.itemPrepId, RecipeEntry.Columns.amount])
        }
    }
    
    func deleteRecipeEntry(recipeEntryId: Int) throws {
        try dbWriter.write { db in
            _ = try RecipeEntry.deleteOne(db, key: recipeEntryId)
        }
    }
}
