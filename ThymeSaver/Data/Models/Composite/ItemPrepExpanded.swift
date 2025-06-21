import GRDB

struct ItemPrepExpanded: Identifiable {
    var prepId: Int
    var itemId: Int
    var prepName: String
    
    var usedIn: [String]
    
    var id: Int { prepId }
    
    static func getItemPreps(_ db: Database, itemId: Int) -> [ItemPrepExpanded] {
        let items: [ItemPrepExpandedFetch] = (try? ItemPrepExpandedFetch.get(itemId: itemId).fetchAll(db)) ?? []
        return items.map {
            ItemPrepExpanded(
                prepId: $0.prepId,
                itemId: $0.itemId,
                prepName: $0.prepName,
                usedIn: $0.usedIn.split(separator: ",", omittingEmptySubsequences: true).map{String($0)}
            )
        }
    }
}

private struct ItemPrepExpandedFetch: FetchableRecord, Identifiable {
    var prepId: Int
    var itemId: Int
    var prepName: String
    
    var usedIn: String
    
    var id: Int { prepId }
    
    init(row: GRDB.Row) throws {
        prepId = row["prepId"]
        itemId = row["itemId"]
        prepName = row["prepName"]
        usedIn = row["usedIn"]
    }
    
    static func get(itemId: Int) -> SQLRequest<ItemPrepExpandedFetch> {
        """
        SELECT
            ItemPreps.prepId,
            ItemPreps.itemId,
            ItemPreps.prepName,
            COALESCE(group_concat(DISTINCT Recipes.recipeName), '') AS usedIn
        FROM ItemPreps
        LEFT JOIN (RecipeEntries NATURAL JOIN Recipes)
            ON RecipeEntries.prepId = ItemPreps.prepId
        WHERE ItemPreps.itemId = \(itemId)
        GROUP BY
            ItemPreps.itemPrepId
        ORDER BY 
            ItemPreps.prepName;
        """
    }
}
