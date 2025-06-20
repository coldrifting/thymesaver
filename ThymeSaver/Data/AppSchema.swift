import Foundation
import GRDB

extension AppDatabase {
    func SetupDatabaseSchema(_ db: Database) throws {
        try db.create(table: Store.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("storeId").notNull()
            t.column("storeName", .text).notNull()
        }
        try db.create(table: Aisle.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("aisleId").notNull()
            t.column("storeId", .integer).notNull()
                .references(Store.databaseTableName, onDelete: .cascade)
            t.column("aisleName", .text).notNull()
            t.column("aisleOrder", .integer).notNull()
        }
        try db.create(table: Item.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("itemId").notNull()
            t.column("itemName", .text).notNull()
            t.column("itemTemp", .text).notNull()
            t.column("defaultUnits", .text).notNull()
            t.column("cartAmount", .text)
        }
        try db.create(table: ItemAisle.databaseTableName) { t in
            t.column("itemId", .integer).notNull()
                .references(Item.databaseTableName, onDelete: .cascade)
            t.column("storeId", .integer).notNull()
                .references(Store.databaseTableName, onDelete: .cascade)
            t.column("aisleId", .integer).notNull()
                .references(Aisle.databaseTableName, onDelete: .cascade)
            t.column("bay", .text).notNull()
            
            t.primaryKey(["itemId", "storeId"])
        }
        try db.create(table: ItemPrep.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("itemPrepId").notNull()
            t.column("itemId", .integer).notNull()
                .references(Item.databaseTableName, onDelete: .cascade)
            t.column("prepName", .text).notNull()
        }
        try db.create(table: Recipe.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("recipeId").notNull()
            t.column("recipeName", .integer).notNull()
            t.column("url", .text)
            t.column("isPinned", .boolean).notNull()
            t.column("cartAmount", .integer).notNull()
        }
        try db.create(table: RecipeStep.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("recipeStepId").notNull()
            t.column("recipeStepContent", .text).notNull()
            t.column("recipeStepOrder", .integer).notNull()
            t.column("isImage", .boolean).notNull()
            t.column("recipeId", .integer).notNull()
                .references(Recipe.databaseTableName, onDelete: .cascade)
        }
        try db.create(table: RecipeSection.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("recipeSectionId").notNull()
            t.column("recipeSectionName", .text).notNull()
            t.column("recipeId", .integer).notNull()
                .references(Recipe.databaseTableName, onDelete: .cascade)
        }
        try db.create(table: RecipeEntry.databaseTableName) { t in
            t.autoIncrementedPrimaryKey("recipeEntryId").notNull()
            t.column("recipeId", .integer).notNull()
                .references(Recipe.databaseTableName, onDelete: .cascade)
            t.column("recipeSectionId", .integer).notNull()
                .references(RecipeSection.databaseTableName, onDelete: .cascade)
            t.column("itemId", .integer).notNull()
                .references(Item.databaseTableName, onDelete: .cascade)
            t.column("itemPrepId", .integer)
                .references(ItemPrep.databaseTableName, onDelete: .cascade)
            t.column("amount", .text).notNull()
            
            t.uniqueKey(["recipeId", "recipeSectionId", "itemId", "itemPrepId"])
        }
        
        try db.create(table: Config.databaseTableName) { t in
            t.primaryKey("id", .integer, onConflict: .replace).check { $0 == 1 }
            t.column("selectedStore", .integer).notNull()
                .references(Store.databaseTableName, onDelete: .restrict)
        }
    }
    
    func reset() throws {
        try dbWriter.write { db in
            try Config.deleteAll(db)
            
            try RecipeEntry.deleteAll(db)
            try RecipeSection.deleteAll(db)
            try RecipeStep.deleteAll(db)
            try Recipe.deleteAll(db)
            
            try ItemPrep.deleteAll(db)
            try ItemAisle.deleteAll(db)
            try Item.deleteAll(db)
            
            try Aisle.deleteAll(db)
            try Store.deleteAll(db)
            
            try decode(db, for: Store.self)
            try decode(db, for: Aisle.self)
            try decode(db, for: Item.self)
            try decode(db, for: ItemAisle.self)
            try decode(db, for: ItemPrep.self)
            try decode(db, for: Recipe.self)
            try decode(db, for: RecipeStep.self)
            try decode(db, for: RecipeSection.self)
            try decode(db, for: RecipeEntry.self)
            
            let config: Config = Config(selectedStore: 1)
            try config.insert(db)
        }
    }
    
    func decode<T: PersistableRecord & Codable>(_ db: Database, for: T.Type) throws {
        let jsonFileName = "\(T.self)".last == "y"
        ? (try? "\(T.self)".replacing(Regex("y$"), with: "ies")) ?? "\(T.self)s"
        : "\(T.self)s"
        
        guard let url = Bundle.main.url(forResource: jsonFileName, withExtension: "json") else {
            fatalError("Failed to find \(jsonFileName).json")
        }
        
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([T].self, from: data)
        
        for item in decoded {
            try item.insert(db)
        }
    }
}

