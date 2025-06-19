import GRDB

struct ItemWithPrep: Identifiable, CustomStringConvertible, Hashable {
    var itemId: Int
    var itemName: String
    
    var itemPrep: Prep? = nil
    
    var id: Int { itemId.concat(itemPrep?.prepId ?? -1) }
    var description: String { itemName }
    
    var nameWithPrep: String {
        if let prep = itemPrep {
            return "\(itemName) - \(prep.prepName)"
        }
        return itemName
    }
    
    struct Prep: Identifiable, Hashable {
        var prepId: Int
        var prepName: String
        
        var id: Int { prepId }
    }
    
    fileprivate init(_ item: ItemWithPrepFetch) {
        self.itemId = item.itemId
        self.itemName = item.itemName
        
        if let prepId = item.itemPrepId, let prepName = item.prepName {
            self.itemPrep = Prep(prepId: prepId, prepName: prepName)
        }
    }
    
    static func getAll(_ db: Database) -> [ItemWithPrep] {
        let entries: [ItemWithPrepFetch] = (try? ItemWithPrepFetch.get().fetchAll(db)) ?? []
        
        return entries.map { entry in ItemWithPrep(entry) }
    }
    
    static func getAllNotInRecipeSections(_ db: Database, recipeId: Int) -> [Int:Set<ItemWithPrep>] {
        var map: [Int:Set<ItemWithPrep>] = [:]
        
        let recipeSectionIds: [Int] = (try? Int.fetchAll(db, sql: "SELECT recipeSectionId FROM RecipeSections WHERE recipeId = \(recipeId)")) ?? []
        
        for recipeSectionId in recipeSectionIds {
            let entries: [ItemWithPrepFetch] = (try? ItemWithPrepFetch.getNotInRecipeSection(recipeSectionId: recipeSectionId).fetchAll(db)) ?? []
            map[recipeSectionId] = Set(entries.map{ ItemWithPrep($0) })
        }
        
        return map
    }
}

private struct ItemWithPrepFetch: FetchableRecord, Identifiable {
    var itemId: Int
    var itemName: String
    var itemPrepId: Int?
    var prepName: String?
    
    var id: Int { itemId.concat(itemPrepId ?? -1) }
    
    init(row: GRDB.Row) throws {
        itemId = row["itemId"]
        itemName = row["itemName"]
        itemPrepId = row["itemPrepId"]
        prepName = row["prepName"]
    }
    
    static func get() -> SQLRequest<ItemWithPrepFetch> {
        """
        SELECT 
            Items.itemId,
            Items.itemName,
            ItemPreps.itemPrepId,
            ItemPreps.prepName
        FROM Items 
        LEFT JOIN ItemPreps 
            ON Items.itemId = ItemPreps.itemId
        ORDER BY
            Items.itemName,
            ItemPreps.prepName;
        """
    }
    
    static func getNotInRecipeSection(recipeSectionId: Int) -> SQLRequest<ItemWithPrepFetch> {
        """
        SELECT 
            Items.itemId, 
            Items.itemname, 
            ItemPreps.itemPrepId, 
            ItemPreps.prepName 
        FROM (
            SELECT * FROM ( SELECT itemId,itemPrepId FROM Items LEFT JOIN ItemPreps USING(itemId) ) 
            EXCEPT SELECT * FROM ( SELECT itemId, itemPrepId FROM RecipeEntries WHERE RecipeSectionId = \(recipeSectionId) )
        )
        LEFT JOIN Items 
            USING (itemId)
        LEFT JOIN ItemPreps 
            USING (itemPrepId)
        ORDER BY
            Items.itemName,
            ItemPreps.prepName;
        """
    }
}
