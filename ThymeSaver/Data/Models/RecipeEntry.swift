import Foundation
import GRDB

struct RecipeEntry: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable, CreateTable {
    var recipeEntryId: Int
    var recipeSectionId: Int
    var recipeId: Int
    var itemId: Int
    var prepId: Int = 0
    var amount: Amount = Amount()
    
    var id: Int { recipeEntryId }
    
    enum Columns {
        static let recipeEntryId = Column(CodingKeys.recipeSectionId)
        static let recipeSectionId = Column(CodingKeys.recipeSectionId)
        static let recipeId = Column(CodingKeys.recipeId)
        static let itemId = Column(CodingKeys.itemId)
        static let prepId = Column(CodingKeys.prepId)
        static let amount = Column(CodingKeys.amount)
    }
    
    static var databaseTableName: String = "RecipeEntries"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: RecipeEntry.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("recipeEntryId")
            t.column("recipeId", .integer).notNull()
                .references(Recipe.databaseTableName, onDelete: .cascade)
            t.column("recipeSectionId", .integer).notNull()
                .references(RecipeSection.databaseTableName, onDelete: .cascade)
            t.column("itemId", .integer).notNull()
                .references(Item.databaseTableName, onDelete: .cascade)
            t.column("prepId", .integer).notNull()
                .references(Prep.databaseTableName, onDelete: .cascade)
            t.column("amount", .text).notNull()
            
            t.uniqueKey(["recipeId", "recipeSectionId", "itemId", "prepId"])
        }
    }
}

struct RecipeEntryInsert: Codable, FetchableRecord, PersistableRecord {
    var recipeSectionId: Int
    var recipeId: Int
    var itemId: Int
    var prepId: Int? = nil
    var amount: Amount
    
    static var databaseTableName: String { RecipeEntry.databaseTableName }
}

extension AppDatabase {
    func addRecipeEntry(recipeSectionId: Int, recipeId: Int, itemId: Int, prepId: Int = 0, amount: Amount = Amount()) {
        try? dbWriter.write { db in
            let recipeEntry = RecipeEntryInsert(
                recipeSectionId: recipeSectionId,
                recipeId: recipeId,
                itemId: itemId,
                prepId: prepId,
                amount: amount
            )
            _ = try recipeEntry.insert(db)
        }
    }
    
    func updateRecipeEntry(recipeEntryId: Int, itemId: Int, prepId: Int = 0, amount: Amount = Amount()) {
        try? dbWriter.write { db in
            let recipeEntry = RecipeEntry(
                recipeEntryId: recipeEntryId,
                recipeSectionId: -1,
                recipeId: -1,
                itemId: itemId,
                prepId: prepId,
                amount: amount
            )
            _ = try recipeEntry.update(db, columns: [
                RecipeEntry.Columns.itemId,
                RecipeEntry.Columns.prepId,
                RecipeEntry.Columns.amount
            ])
        }
    }
    
    func deleteRecipeEntry(recipeEntryId: Int) {
        try? dbWriter.write { db in
            _ = try RecipeEntry.deleteOne(db, key: recipeEntryId)
        }
    }
}
