import GRDB

struct RecipeTree: Identifiable {
    var recipeId: Int = -1
    var recipeName: String = ""
    var url: String? = nil
    var steps: String? = nil
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
    
    var id: Int { itemId }
}

struct ItemPrepTree: Identifiable {
    var itemPrepId: Int
    var prepName: String
    
    var id: Int { itemPrepId }
}

struct RecipeExpanded: FetchableRecord, Identifiable {
    // Recipe
    var recipeId: Int
    var recipeName: String
    var url: String?
    var steps: String?
    
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
    var itemPrepId: Int?
    var prepName: String?
    
    var id: Int { recipeEntryId ?? -1 }
    
    init(row: GRDB.Row) throws {
        recipeId = row["recipeId"]
        recipeName = row["recipeName"]
        url = row["url"]
        steps = row["steps"]
        
        recipeSectionId = row["recipeSectionId"]
        recipeSectionName = row["recipeSectionName"]
        
        recipeEntryId = row["recipeEntryId"]
        
        itemId = row["itemId"]
        itemName = row["itemName"]
        itemTemp = row["itemTemp"]
        defaultUnits = row["defaultUnits"]
        
        itemPrepId = row["itemPrepId"]
        prepName = row["prepName"]
        amount = row["amount"]
    }
    
    static func get(recipeId: Int) -> SQLRequest<RecipeExpanded> {
        """
        SELECT
            Recipes.recipeId,
            Recipes.recipeName,
            Recipes.url,
            Recipes.steps,
            RecipeSections.recipeSectionId,
            RecipeSections.recipeSectionName,
            RecipeEntries.recipeEntryId,
            RecipeEntries.amount,
            Items.itemId,
            Items.itemName,
            Items.itemTemp,
            itemPreps.itemPrepId,
            itemPreps.prepName
        FROM Recipes
        LEFT JOIN RecipeSections
            ON Recipes.recipeId = RecipeSections.recipeId
        LEFT JOIN RecipeEntries 
            ON RecipeEntries.recipeSectionId = RecipeSections.recipeSectionId
        LEFT JOIN Items
            ON Items.itemId = RecipeEntries.ItemId
        LEFT JOIN ItemPreps
            ON ItemPreps.itemPrepId = RecipeEntries.itemPrepId
        WHERE Recipes.recipeId = \(recipeId)
        ORDER BY 
            RecipeSections.recipeSectionId,
            Items.itemTemp,
            Items.itemName,
            ItemPreps.prepName;
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
            
            let itemPrep : ItemPrepTree? = entry.itemPrepId != nil
            ? ItemPrepTree(
                itemPrepId: entry.itemPrepId!,
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
            steps: entries[0].steps,
            recipeSections: sectionMap.values.sorted(by: { $0.recipeSectionId < $1.recipeSectionId }))
        
        return recipe
    }
}
