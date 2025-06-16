import GRDB

struct ItemPrepExpanded: FetchableRecord, Identifiable {
    // ItemPrep
    var itemPrepId: Int
    var itemId: Int
    var prepName: String
    
    var usedIn: String
    
    var id: Int { itemPrepId }
    
    init(row: GRDB.Row) throws {
        itemPrepId = row["itemPrepId"]
        itemId = row["itemId"]
        prepName = row["prepName"]
        usedIn = row["usedIn"]
    }
    
    static func get(itemId: Int) -> SQLRequest<ItemPrepExpanded> {
            """
                SELECT
                    ItemPreps.itemPrepId,
                    ItemPreps.itemId,
                    ItemPreps.prepName,
                    COALESCE(group_concat(DISTINCT Recipes.recipeName), '') AS usedIn
                FROM ItemPreps
                LEFT JOIN (RecipeEntries NATURAL JOIN Recipes)
                    ON RecipeEntries.itemId = ItemPreps.itemId
                WHERE ItemPreps.itemId = \(itemId)
                GROUP BY
                    ItemPreps.itemPrepId
                ORDER BY 
                    ItemPreps.prepName;
            """
    }
    
    static func getItemPreps(_ db: Database, itemId: Int) throws -> [ItemPrepExpanded] {
        try ItemPrepExpanded.get(itemId: itemId).fetchAll(db)
    }
}
