import Foundation
import GRDB

struct Recipe: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable {
    var recipeId: Int
    var recipeName: String
    var url: String? = nil
    var isPinned: Bool = false
    var cartAmount: Int = 0
    
    var id: Int { recipeId }
    
    enum Columns {
        static let recipeId = Column(CodingKeys.recipeId)
        static let recipeName = Column(CodingKeys.recipeName)
        static let url = Column(CodingKeys.url)
        static let isPinned = Column(CodingKeys.isPinned)
        static let cartAmount = Column(CodingKeys.cartAmount)
    }
    
    static var databaseTableName: String = "Recipes"
}

struct RecipeInsert: Codable, FetchableRecord, PersistableRecord {
    var recipeName: String
    var url: String? = nil
    var isPinned: Bool = false
    var cartAmount: Int = 0
    
    static var databaseTableName: String { Recipe.databaseTableName }
}

extension AppDatabase {
    func addRecipe(recipeName: String) {
        try? dbWriter.write { db in
            let recipe = RecipeInsert(recipeName: recipeName)
            _ = try recipe.insert(db)
            
            let recipeId: Int = try Int.fetchOne(db, sql: "SELECT last_insert_rowid()")!
            let recipeSection = RecipeSectionInsert(recipeSectionName: "Main", recipeId: recipeId)
            _ = try recipeSection.insert(db)
        }
    }
    
    func deleteRecipe(recipeId: Int) {
        try? dbWriter.write { db in
            _ = try Recipe.deleteOne(db, key: recipeId)
        }
    }
    
    func renameRecipe(recipeId: Int, newName: String) {
        try? dbWriter.write { db in
            var recipe = try Recipe.find(db, key: recipeId)
            recipe.recipeName = newName
            try recipe.update(db, columns: [Recipe.Columns.recipeName])
        }
    }
    
    func toggleRecipePin(recipeId: Int) {
        try? dbWriter.write { db in
            var recipe = try Recipe.find(db, key: recipeId)
            recipe.isPinned = !recipe.isPinned
            try recipe.update(db, columns: [Recipe.Columns.isPinned])
        }
    }
    
    func updateRecipeUrl(recipeId: Int, newUrl: String) {
        try? dbWriter.write { db in
            var recipe = try Recipe.find(db, key: recipeId)
            recipe.url = newUrl
            try recipe.update(db, columns: [Recipe.Columns.url])
        }
    }
}
