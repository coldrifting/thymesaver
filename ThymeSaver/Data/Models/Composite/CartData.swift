import GRDB

// Used to import data into the cart
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
    
    // Combines entries of the same item that have the same amount type (Count, Volume, or Weight)
    static func combine(cartData: [CartData]) -> [CartData] {
        var map: [Int:CartData] = [:]
        
        let items = cartData.map { data in
            map[data.itemId] = data
            return Item(itemId: data.itemId, itemName: data.itemName, itemTemp: data.itemTemp, defaultUnits: data.defaultUnits, cartAmount: data.amount)
        }
        
        let combinedItems = combine(items: items)
        
        let finalData = combinedItems.map { item in
            CartData(
                itemId: item.itemId,
                itemName: item.itemName,
                itemTemp: item.itemTemp,
                defaultUnits: item.defaultUnits,
                aisleId: map[item.itemId]?.aisleId ?? -1,
                aisleOrder: map[item.itemId]?.aisleOrder ?? -1,
                aisleName: map[item.itemId]?.aisleName ?? "Not Found",
                bay: map[item.itemId]?.bay ?? BayType.middle,
                amount: item.cartAmount ?? Amount()
            )
        }
        
        return finalData
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
        FROM (SELECT 
            itemId, 
            itemName, 
            itemTemp, 
            defaultUnits, 
            amount, 
            cartAmount, 
            storeId, 
            aisleId, 
            bay 
        FROM (SELECT *
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
        LEFT JOIN ItemAisles 
            USING (itemId) 
        UNION ALL 
        SELECT     itemId, 
            itemName, 
            itemTemp, 
            defaultUnits, 
            amount, 
            cartAmount,
            NULL,
            NULL,
            NULL
        FROM (SELECT *
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
                        WHERE  amount > 0)))
        LEFT JOIN Aisles USING (aisleId)
        WHERE Aisles.storeId = (SELECT selectedStore FROM Config) OR Aisles.storeId IS NULL
        GROUP BY itemId, amount
        ORDER BY aisleOrder, itemName
        """
    }
}
