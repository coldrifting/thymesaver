import GRDB

struct ItemExpanded: Identifiable {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    var aisleId: Int?
    var aisleName: String?
    var aisleOrder: Int?
    
    var usedIn: [String]
    
    var id: Int { itemId }
    
    static func getItemsFiltered(_ db: Database, itemNameFilter: String = "") -> [ItemExpanded] {
        let items: [ItemExpandedFetch] = (try? ItemExpandedFetch.filter(itemNameFilter: itemNameFilter).fetchAll(db)) ?? []
        return items.map {
            ItemExpanded(
                itemId: $0.itemId,
                itemName: $0.itemName,
                itemTemp: $0.itemTemp,
                defaultUnits: $0.defaultUnits,
                usedIn: $0.usedIn.split(separator: ",", omittingEmptySubsequences: true).map{String($0)}
            )
        }
    }
}

private struct ItemExpandedFetch: FetchableRecord, Identifiable {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    var aisleId: Int?
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
    static func filter(itemNameFilter: String = "") -> SQLRequest<ItemExpandedFetch> {
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
}
