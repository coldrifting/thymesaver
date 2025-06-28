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
        
        var results : [Item] = []
        
        var itemDict: [Int:Item] = [:]
        
        var eaches: [Int:Amount] = [:]
        var volume: [Int:Amount] = [:]
        var weight: [Int:Amount] = [:]
        
        for item in items {
            itemDict[item.itemId] = item
            
            if let cartAmount = item.cartAmount {
                
                if (cartAmount.type.category == .count) {
                    var curEaches = eaches[item.itemId] ?? Amount(0, type: .count)
                    curEaches = curEaches + cartAmount
                    eaches[item.itemId] = curEaches
                }
                
                if (cartAmount.type.category == .volume) {
                    var curVolume = volume[item.itemId] ?? Amount(0, type: cartAmount.type)
                    curVolume = curVolume + cartAmount
                    volume[item.itemId] = curVolume
                }
                
                if (cartAmount.type.category == .weight) {
                    var curWeight = weight[item.itemId] ?? Amount(0, type: cartAmount.type)
                    curWeight = curWeight + cartAmount
                    weight[item.itemId] = curWeight
                }
            }
        }
        
        for (itemId, item) in itemDict {
            if let eachesAmount = eaches[itemId] {
                let newItem = Item(item: item, newAmount: eachesAmount)
                results.append(newItem)
            }
            
            if let volumeAmount = volume[itemId] {
                let newItem = Item(item: item, newAmount: volumeAmount)
                results.append(newItem)
            }
            
            if let weightAmount = weight[itemId] {
                let newItem = Item(item: item, newAmount: weightAmount)
                results.append(newItem)
            }
        }
        
        return results
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
