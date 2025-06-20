import GRDB

struct RecipeTree: Identifiable {
    var recipeId: Int = -1
    var recipeName: String = ""
    var url: String? = nil
    var recipeSections: [RecipeSectionTree] = []
    
    var id: Int { recipeId }
}

struct RecipeSectionTree: Identifiable {
    var recipeSectionId: Int
    var recipeSectionName: String
    var items: [ItemTree]
    
    var id: Int { recipeSectionId }
}

struct ItemTree: Identifiable {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var itemPrep: ItemPrepTree?
    
    var entryId: Int
    var amount: Amount
    var isChecked: Bool = false
    
    var id: Int { itemId.concat(itemPrep?.prepId ?? -1) }
}

struct ItemPrepTree: Identifiable {
    var prepId: Int
    var prepName: String
    
    var id: Int { prepId }
}

struct RecipeExpanded: FetchableRecord, Identifiable {
    // Recipe
    var recipeId: Int
    var recipeName: String
    var url: String?
    
    // RecipeSection
    var recipeSectionId: Int?
    var recipeSectionName: String?
    var recipeSectionOrder: Int?
    
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
        recipeId = row["recipeId"]
        recipeName = row["recipeName"]
        url = row["url"]
        
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
    
    static func get(recipeId: Int) -> SQLRequest<RecipeExpanded> {
        """
        SELECT
            Recipes.recipeId,
            Recipes.recipeName,
            Recipes.url,
            RecipeSections.recipeSectionId,
            RecipeSections.recipeSectionName,
            RecipeEntries.recipeEntryId,
            RecipeEntries.amount,
            Items.itemId,
            Items.itemName,
            Items.itemTemp,
            RecipeEntries.prepId,
            Preps.prepName
        FROM Recipes
        LEFT JOIN RecipeSections
            ON Recipes.recipeId = RecipeSections.recipeId
        LEFT JOIN RecipeEntries 
            ON RecipeEntries.recipeSectionId = RecipeSections.recipeSectionId
        LEFT JOIN Items
            ON Items.itemId = RecipeEntries.ItemId
        LEFT JOIN Preps
            ON Preps.prepId = RecipeEntries.prepId
        WHERE Recipes.recipeId = \(recipeId)
        ORDER BY 
            RecipeSections.recipeSectionId,
            Items.itemTemp,
            Items.itemName,
            Preps.prepName;
        """
    }
    
    static func getRecipeEntries(_ db: Database, recipeId: Int) throws -> RecipeTree {
        let entries: [RecipeExpanded] = try RecipeExpanded.get(recipeId: recipeId).fetchAll(db)
        
        if (entries.isEmpty) {
            return RecipeTree()
        }
        
        var sectionMap = Dictionary<Int, RecipeSectionTree>()
        
        for entry in entries {
            guard let sectionId = entry.recipeSectionId else {
                continue
            }
            
            let itemPrep : ItemPrepTree? = entry.prepId != nil
            ? ItemPrepTree(
                prepId: entry.prepId!,
                prepName: entry.prepName!)
            : nil
            
            let item : ItemTree? = entry.itemId != nil
            ? ItemTree(
                itemId: entry.itemId!,
                itemName: entry.itemName!,
                itemTemp: entry.itemTemp!,
                itemPrep: itemPrep,
                entryId: entry.recipeEntryId!,
                amount: entry.amount!)
            : nil
            
            var section = sectionMap[sectionId] ?? RecipeSectionTree(
                recipeSectionId: sectionId,
                recipeSectionName: entry.recipeSectionName!,
                items: [])
            
            if let itemNotNil = item {
                section.items.append(itemNotNil)
            }
            
            sectionMap[sectionId] = section
        }
        
        let recipe: RecipeTree = RecipeTree(
            recipeId: entries[0].recipeId,
            recipeName: entries[0].recipeName,
            url: entries[0].url,
            recipeSections: sectionMap.values.sorted(by: { $0.recipeSectionId < $1.recipeSectionId }))
        
        return recipe
    }
}
