import SwiftUI
import SwiftData

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
        
        // TODO
        
        // Items
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
