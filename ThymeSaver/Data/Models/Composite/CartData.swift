import GRDB

struct CartAisle: Identifiable, Comparable {
    var aisleId: Int
    var aisleOrder: Int
    var aisleName: String
    var bay: BayType
    
    var items: [Item] = []
    
    var id: Int { aisleId }
    
    static func < (lhs: CartAisle, rhs: CartAisle) -> Bool {
        if (lhs.aisleOrder != rhs.aisleId) {
            return lhs.aisleOrder < rhs.aisleOrder
        }
        
        return lhs.aisleName < rhs.aisleName
    }
    
    static func fetchAll(_ db: Database) -> [CartAisle] {
        let allData: [CartData] = (try? CartData.all(db).fetchAll(db)) ?? []
        
        let map: [Int:CartAisle] = [:]
        let transformed = allData
            .reduce(into: map) { aisles, entry in
                let aisleId: Int = entry.aisleId ?? -1
                let aisleOrder = entry.aisleOrder ?? -1
                let aisleName = entry.aisleName ?? "No Aisle Set"
                let bay = entry.bay ?? BayType.middle
                
                var aisle: CartAisle = aisles[aisleId] ?? CartAisle(aisleId: aisleId, aisleOrder: aisleOrder, aisleName: aisleName, bay: bay)
                
                let item = Item(
                    itemId: entry.itemId,
                    itemName: entry.itemName,
                    itemTemp: entry.itemTemp,
                    defaultUnits: entry.defaultUnits,
                    cartAmount: entry.amount * entry.cartAmount
                )
                
                var items = aisle.items
                items.append(item)
                aisle.items = items
                
                aisles[aisleId] = aisle
            }
            .values.sorted()
            .map { a in
                var aisle = a
                aisle.items = combine(items: aisle.items)
                return aisle
            }
        
        return transformed
    }
    
    static func combine(items: [Item]) -> [Item] {
        
        var results : [Item] = items
        
        //return results
        
        for x in stride(from: 0, to: items.count, by: 1) {
            for y in stride(from: 0, to: items.count, by: 1) {
                if (x == y) {
                    continue
                }
                
                if (results[x].itemId == results[y].itemId &&
                    results[x].cartAmount?.type.category == results[y].cartAmount?.type.category) {
                    
                    if let a = items[x].cartAmount, let b = items[y].cartAmount {
                        results[x].cartAmount = Amount(0, type: UnitType.count)
                        results[y].cartAmount = a + b
                    }
                }
            }
        }
        
        return results.filter{ $0.cartAmount?.fraction.toDouble() ?? 0 > 0}
    }
    
}

struct CartData: FetchableRecord, Decodable {
    var itemId: Int
    var itemName: String
    var itemTemp: ItemTemp
    var defaultUnits: UnitType
    
    var aisleId: Int?
    var aisleOrder: Int?
    var aisleName: String?
    var bay: BayType?
    
    var amount: Amount = Amount()
    var cartAmount: Int = 1
    
    static func all(_ db: Database) -> SQLRequest<CartData> {
        """
        SELECT itemId,
               itemName,
               itemTemp,
               defaultUnits,
               aisleId,
               aisleOrder,
               aisleName,
               bay,
               amount,
               cartAmount
        FROM   (SELECT *
                FROM   (SELECT itemId,
                               itemName,
                               itemTemp,
                               defaultUnits,
                               amount,
                               recipes.cartAmount
                        FROM   recipes
                               natural JOIN recipeSections
                               natural JOIN recipeEntries
                               JOIN items using (itemId)
                        WHERE  recipes.cartAmount > 0)
                UNION ALL
                SELECT *
                FROM   (SELECT itemId,
                               itemName,
                               itemTemp,
                               defaultUnits,
                               cartAmount AS amount,
                               1          AS cartAmount
                        FROM   items
                        WHERE  amount > 0))
               LEFT JOIN itemAisles using (itemId)
               LEFT JOIN aisles using (aisleId)
        WHERE  itemAisles.storeId = (SELECT selectedStore FROM Config)
                OR itemAisles.storeId IS NULL
        ORDER  BY itemAisles.storeId DESC,
                  aisleOrder,
                  itemName
        """
    }
}
