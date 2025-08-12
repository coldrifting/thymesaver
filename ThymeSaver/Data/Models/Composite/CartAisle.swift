import GRDB

struct CartAisle: Identifiable, Comparable {
    var aisleId: Int
    var aisleOrder: Int
    var aisleName: String
    var bay: BayType
    
    var entries: [CartEntry] = []
    
    var id: Int { aisleId }
    
    static func < (lhs: CartAisle, rhs: CartAisle) -> Bool {
        if (lhs.aisleOrder != rhs.aisleId) {
            return lhs.aisleOrder < rhs.aisleOrder
        }
        
        return lhs.aisleName < rhs.aisleName
    }
    
    static func fetchAll(_ db: Database) -> [CartAisle] {
        let allData: [CartEntry] = (try? CartEntry.fetchAll(db)) ?? []
        
        let map: [Int:CartAisle] = [:]
        let transformed = allData
            .reduce(into: map) { aisles, entry in
                let aisleId: Int = entry.aisleId
                let aisleOrder = entry.aisleOrder
                let aisleName = entry.aisleName
                let bay = entry.bay
                
                var aisle: CartAisle = aisles[aisleId] ?? CartAisle(aisleId: aisleId, aisleOrder: aisleOrder, aisleName: aisleName, bay: bay)
                
                var items = aisle.entries
                items.append(entry)
                aisle.entries = items
                
                aisles[aisleId] = aisle
            }
            .values.sorted()
        
        return transformed
    }
}
