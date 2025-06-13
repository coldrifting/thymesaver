import SwiftUI
import SwiftData
import GRDB

func grdb() -> DatabaseQueue {
    do {
        // 1. Open a database connection
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        let directoryURL = appSupportURL.appendingPathComponent("MyDatabase", isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        
        // Open or create the database
        let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
        let dbQueue: DatabaseQueue = try DatabaseQueue(path: databaseURL.path)
        
        // 2. Define the database schema
        try dbQueue.write { db in
            try? db.drop(table: "store")
            
            try db.create(table: "store") { t in
                t.primaryKey("storeId", .integer).notNull()
                t.column("storeName", .text).notNull()
            }
            
            try Store(storeId: 1, storeName: "Store 1").insert(db)
            try Store(storeId: 2, storeName: "Shop B").insert(db)
        }
        
        return dbQueue
    }
    catch {
        fatalError("Unable to init DB: \(error)")
    }
}
/*
@MainActor
func populate(context: ModelContext) {
    context.autosaveEnabled = false
    do {
        for model in schemaTypes.reversed() {
            try context.delete(model: model)
        }
        try context.save()
    } catch {
        fatalError("Failed to clear all pre-existing data.")
    }
    
    guard let storesURL = Bundle.main.url(forResource: "Stores", withExtension: "json") else {
        fatalError("Failed to find Stores.json")
    }
    
    guard let aislesURL = Bundle.main.url(forResource: "Aisles", withExtension: "json") else {
        fatalError("Failed to find Aisles.json")
    }
    
    guard let itemsURL = Bundle.main.url(forResource: "Items", withExtension: "json") else {
        fatalError("Failed to find Items.json")
    }

    do {
        // Stores
        let storesData = try Data(contentsOf: storesURL)
        let stores = try JSONDecoder().decode([Store].self, from: storesData)
        
        for store in stores {
            context.insert(store)
        }
        try context.save()
        
        // Aisles
        let aisleData = try Data(contentsOf: aislesURL)
        let aisleTempData = try JSONDecoder().decode([AisleJson].self, from: aisleData)
        
        for aisleTemp in aisleTempData {
            if let store : Store = stores.first(where: {$0.uuid == UUID.init(number: aisleTemp.storeId)}) {
                context.insert(aisleTemp.ToAisle(store: store))
            }
        }
        
        // Items
        let itemData = try Data(contentsOf: itemsURL)
        let itemTempData = try JSONDecoder().decode([Item].self, from: itemData)
        
        for itemEntry in itemTempData {
            context.insert(itemEntry)
        }
        
        // TODO

        // ItemAisles
        // ItemPreps
        
        // Recipes
        // RecipeSections
        // RecipeEntries
    } catch {
        print ("Error: \(error)")
    }
    
    try? context.save()
    context.autosaveEnabled = true
}
*/
