import GRDB

struct ItemWithPrep: Identifiable, CustomStringConvertible {
    var itemId: Int
    var itemName: String
    
    var itemPrep: Prep? = nil
    
    var id: Int { itemId.concat(itemPrep?.prepId ?? -1) }
    var description: String { itemName }
    
    struct Prep {
        var prepId: Int
        var prepName: String
    }
    
    static func getAll(_ db: Database) -> [ItemWithPrep] {
        let entries: [ItemWithPrepFetch] = (try? ItemWithPrepFetch.get().fetchAll(db)) ?? []
        
        return entries.map { entry in
            if let prepId = entry.itemPrepId, let prepName = entry.prepName {
                ItemWithPrep(itemId: entry.itemId, itemName: entry.itemName, itemPrep: ItemWithPrep.Prep(prepId: prepId, prepName: prepName))
            }
            else {
                ItemWithPrep(itemId: entry.itemId, itemName: entry.itemName)
            }
        }
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
}
