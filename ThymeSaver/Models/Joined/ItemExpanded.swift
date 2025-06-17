import GRDB

struct ItemExpanded: FetchableRecord, Identifiable {
    // Item
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    // ItemAisle
    //var itemId: Int
    var aisleId: Int?
    //var storeId: Int
    //var bay: BayType = BayType.middle
    
    // Aisle
    //var aisleId: Int
    //var storeId: Int
    var aisleName: String?
    var aisleOrder: Int?
    
    var usedIn: String = ""
    
    var id: Int { itemId }
    
    init(row: GRDB.Row) throws {
        itemId = row["itemId"]
        itemName = row["itemName"]
        itemTemp = row["itemTemp"]
        defaultUnits = row["defaultUnits"]
        aisleId = row["aisleId"]
        aisleName = row["aisleName"]
        aisleOrder = row["aisleOrder"]
        usedIn = row["usedIn"]
    }
    
    // TODO: - Check cart as well? -
    static func filter(itemNameFilter: String = "") -> SQLRequest<ItemExpanded> {
        """
        SELECT
            Items.itemId, 
            Items.itemName, 
            Items.itemTemp, 
            Items.defaultUnits,
            ItemAisles.aisleId, 
            Aisles.aisleName, 
            Aisles.aisleOrder,
            COALESCE(group_concat(DISTINCT Recipes.recipeName), '') AS usedIn
        FROM Items
        LEFT JOIN (RecipeEntries NATURAL JOIN Recipes)
            ON RecipeEntries.itemId = Items.itemId
        LEFT JOIN ItemAisles 
            ON Items.itemId = ItemAisles.itemId 
            AND ItemAisles.storeId = (SELECT COALESCE((SELECT selectedStore FROM Config), 0))
        LEFT JOIN Aisles 
            USING (aisleId)
        WHERE Items.itemName 
            LIKE '%' || \(itemNameFilter) || '%'
        GROUP BY
            Items.itemId
        ORDER BY 
            LOWER(Items.itemName), 
            Aisles.aisleOrder, 
            Items.itemTemp;
        """
    }
    
    static func getItemsFiltered(_ db: Database, itemNameFilter: String = "") throws -> [ItemExpanded] {
        try ItemExpanded.filter(itemNameFilter: itemNameFilter).fetchAll(db)
    }
}
