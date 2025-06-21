import Foundation
import GRDB

struct RecipeSection: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable, CreateTable {
    var recipeSectionId: Int
    var recipeSectionName: String
    var recipeId: Int
    
    var id: Int { recipeSectionId }
    
    enum Columns {
        static let recipeSectionId = Column(CodingKeys.recipeSectionId)
        static let recipeSectionName = Column(CodingKeys.recipeSectionName)
        static let recipeId = Column(CodingKeys.recipeId)
    }
    
    static var databaseTableName: String = "RecipeSections"
    
    static func createTable(_ db: Database) throws {
        try db.create(table: RecipeSection.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("recipeSectionId")
            t.column("recipeSectionName", .text).notNull()
            t.column("recipeId", .integer).notNull()
                .references(Recipe.databaseTableName, onDelete: .cascade)
        }
    }
    
    static func getAllSectionIds(_ db: Database, recipeId: Int) -> [Int] {
        return (try? RecipeSection
            .filter{ $0.recipeId == recipeId }
            .select({ $0.recipeSectionId }, as: Int.self)
            .fetchAll(db)) ?? []
    }
}

struct RecipeSectionInsert: Codable, FetchableRecord, PersistableRecord {
    var recipeSectionName: String
    var recipeId: Int
    
    static var databaseTableName: String { RecipeSection.databaseTableName }
}

extension AppDatabase {
    func addRecipeSection(recipeSectionName: String, recipeId: Int) {
        try? dbWriter.write { db in
            let recipeSection = RecipeSectionInsert(recipeSectionName: recipeSectionName, recipeId: recipeId)
            try recipeSection.insert(db)
        }
    }
    
    func renameRecipeSection(recipeSectionId: Int, newName: String) {
        try? dbWriter.write { db in
            var recipeSection = try RecipeSection.find(db, key: recipeSectionId)
            recipeSection.recipeSectionName = newName
            try recipeSection.update(db, columns: [RecipeSection.Columns.recipeSectionName])
        }
    }
    
    func deleteRecipeSection(recipeId: Int, recipeSectionId: Int) {
        try? dbWriter.write { db in
            let numSections = try RecipeSection.filter{$0.recipeId == recipeId}.fetchAll(db).count
            if (numSections > 1) {
                _ = try RecipeSection.deleteOne(db, key: recipeSectionId)
            }
        }
    }
}
