import GRDB

struct RecipeSect: Identifiable {
    var id: Int { recipeSectionId }
    
    var recipeSectionId: Int
    var recipeSectionName: String
    
    var entries: [RecipeEnt] = []
    
    static func fetchAll(_ db: Database, recipeId: Int) -> [RecipeSect] {
        let arr = (try? RecipeSectFetch.get(recipeId: recipeId).fetchAll(db)) ?? []
        
        var allSects : [Int:RecipeSect] = [:]
        
        for entry in arr {
            var sect = allSects[entry.recipeSectionId] ?? RecipeSect(
                recipeSectionId: entry.recipeSectionId,
                recipeSectionName: entry.recipeSectionName
            )
            
            if let entryId = entry.recipeEntryId,
               let amount = entry.amount,
               let itemId = entry.itemId,
               let itemName = entry.itemName,
               let itemTemp = entry.itemTemp,
               let defaultUnits = entry.defaultUnits,
               let prepId = entry.prepId,
               let prepName = entry.prepName {
                
                let item: Item = Item(
                    itemId: itemId,
                    itemName: itemName,
                    itemTemp: itemTemp,
                    defaultUnits: defaultUnits
                )
                
                let prep: Prep = Prep(
                    prepId: prepId,
                    prepName: prepName
                )
                
                let entry: RecipeEnt = RecipeEnt(recipeEntryId: entryId, amount: amount, item: item, prep: prep)
                var newEntries = sect.entries.map{$0}
                newEntries.append(entry)
                sect.entries = newEntries
                
            }
            
            allSects[entry.recipeSectionId] = sect
        }
        
        return allSects.values.sorted { $0.recipeSectionId < $1.recipeSectionId }
    }
}

struct RecipeEnt: Identifiable {
    var id: Int { recipeEntryId }
    
    var recipeEntryId: Int
    var amount: Amount
    var item: Item
    var prep: Prep
}

private struct RecipeSectFetch: FetchableRecord, Identifiable {
    // RecipeSection
    var recipeSectionId: Int
    var recipeSectionName: String
    
    // RecipeEntry
    var recipeEntryId: Int?
    var amount: Amount?
    
    // Item
    var itemId: Int?
    var itemName: String?
    var itemTemp: ItemTemp?
    var defaultUnits: UnitType?
    
    // ItemPrep
    var prepId: Int?
    var prepName: String?
    
    var id: Int { recipeEntryId ?? -1 }
    
    init(row: GRDB.Row) throws {
        recipeSectionId = row["recipeSectionId"]
        recipeSectionName = row["recipeSectionName"]
        
        recipeEntryId = row["recipeEntryId"]
        
        itemId = row["itemId"]
        itemName = row["itemName"]
        itemTemp = row["itemTemp"]
        defaultUnits = row["defaultUnits"]
        
        prepId = row["prepId"]
        prepName = row["prepName"]
        amount = row["amount"]
    }
    
    static func get(recipeId: Int) -> SQLRequest<RecipeSectFetch> {
        """
        SELECT
            RecipeSections.recipeSectionId,
            RecipeSections.recipeSectionName,
            RecipeEntries.recipeEntryId,
            RecipeEntries.amount,
            Items.itemId,
            Items.itemName,
            Items.itemTemp,
            Items.defaultUnits,
            RecipeEntries.prepId,
            Preps.prepName
        FROM RecipeSections
        LEFT JOIN RecipeEntries 
            ON RecipeEntries.recipeSectionId = RecipeSections.recipeSectionId
        LEFT JOIN Items
            ON Items.itemId = RecipeEntries.ItemId
        LEFT JOIN Preps
            ON Preps.prepId = RecipeEntries.prepId
        WHERE RecipeSections.recipeId = \(recipeId)
        ORDER BY 
            RecipeSections.recipeSectionId,
            Items.itemTemp,
            Items.itemName,
            Preps.prepName;
        """
    }
}
