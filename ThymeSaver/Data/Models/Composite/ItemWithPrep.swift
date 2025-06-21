import GRDB

struct ItemWithPrep: Identifiable, CustomStringConvertible, Hashable {
    var item: Item
    var prep: Prep
    
    var id: Int { item.itemId.concat(prep.prepId) }
    var description: String { item.itemName }
    
    var nameWithPrep: String {
        return "\(item.itemName) - \(prep.prepName)"
    }
    
    fileprivate init(_ item: ItemWithPrepFetch) {
        self.item = Item(
            itemId: item.itemId,
            itemName: item.itemName,
            itemTemp: item.itemTemp,
            defaultUnits: item.defaultUnits
        )
        
        self.prep = Prep(
            prepId: item.prepId,
            prepName: item.prepName
        )
    }
    
    static func getDefaultPreps(_ db: Database) -> [Item:Set<Prep>] {
        let entries: [ItemWithPrepFetch] = (try? ItemWithPrepFetch.getDefaults().fetchAll(db)) ?? []
        
        return ItemWithPrep.toMap(entries.map{ ItemWithPrep($0) } )
    }
    
    static func getValidPerRecipeSection(_ db: Database, recipeId: Int) -> [Int:[Item:Set<Prep>]] {
        var result: [Int:[Item:Set<Prep>]] = [:]
        
        let recipeSectionIds: [Int] = RecipeSection.getAllSectionIds(db, recipeId: recipeId)
        
        for recipeSectionId in recipeSectionIds {
            let entries: [ItemWithPrepFetch] = (try? ItemWithPrepFetch.getNotInRecipeSection(recipeSectionId: recipeSectionId).fetchAll(db)) ?? []
            result[recipeSectionId] = ItemWithPrep.toMap(entries.map{ ItemWithPrep($0) })
        }
        
        return result
    }
    
    static func toMap(_ itemWithPreps: [ItemWithPrep]) -> [Item:Set<Prep>] {
        var result: [Item:Set<Prep>] = [:]
        
        for (itemWithPrep) in itemWithPreps {
            var preps: Set<Prep> = result[itemWithPrep.item] ?? []
            preps.insert(itemWithPrep.prep)
            result[itemWithPrep.item] = preps
        }
        
        return result
    }
}

private struct ItemWithPrepFetch: FetchableRecord, Identifiable {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    var prepId: Int
    var prepName: String
    
    var id: Int { itemId.concat(prepId) }
    
    init(row: GRDB.Row) throws {
        itemId = row["itemId"]
        itemName = row["itemName"]
        itemTemp = row["itemTemp"]
        defaultUnits = row["defaultUnits"]
        prepId = row["prepId"]
        prepName = row["prepName"]
    }
    
    static func getDefaults() -> SQLRequest<ItemWithPrepFetch> {
        """
        SELECT 
            Items.itemId, 
            Items.itemname, 
            Items.itemTemp,
            Items.defaultUnits,
            Preps.prepId, 
            Preps.prepName 
        FROM ( SELECT itemId, COALESCE(prepId, 0) as prepId FROM Items LEFT JOIN ItemPreps USING(itemId) UNION SELECT itemId, 0 FROM Items ) 
        NATURAL JOIN Items
        NATURAL JOIN Preps
        ORDER BY
            Items.itemName,
            Preps.prepName;
        """
    }
    
    static func getNotInRecipeSection(recipeSectionId: Int) -> SQLRequest<ItemWithPrepFetch> {
        """
        SELECT 
            Items.itemId, 
            Items.itemname, 
            Items.itemTemp,
            Items.defaultUnits,
            Preps.prepId, 
            Preps.prepName 
        FROM (
            SELECT * FROM ( SELECT itemId, COALESCE(prepId, 0) as prepId FROM Items LEFT JOIN ItemPreps USING(itemId) UNION SELECT itemId, 0 FROM Items ) 
            EXCEPT SELECT * FROM ( SELECT itemId, prepId FROM RecipeEntries WHERE RecipeSectionId = \(recipeSectionId) )
        )
        NATURAL JOIN Items
        NATURAL JOIN Preps
        ORDER BY
            Items.itemName,
            Preps.prepName;
        """
    }
}
