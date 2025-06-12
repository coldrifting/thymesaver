import Foundation
import SwiftData

@Model
final class Aisle {
    private(set) var uuid: UUID
    var name: String
    var store: Store
    var order: Int
    
    init(name: String, store: Store, order: Int = -1, uuid: UUID? = nil) {
        self.name = name
        self.store = store
        self.order = order
        self.uuid = uuid ?? UUID()
    }
}

final class AisleJson: Codable {
    enum CodingKeys: CodingKey {
        case aisleId
        case aisleName
        case aisleOrder
        case storeId
    }
    
    var aisleId: Int64
    var aisleName: String
    var aisleOrder: Int
    var storeId: Int64
    
    func ToAisle(store: Store) -> Aisle {
        return Aisle(
            name: aisleName,
            store: store,
            order: aisleOrder,
            uuid: UUID.init(number: aisleId))
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.aisleId = try container.decode(Int64.self, forKey: .aisleId)
        self.aisleName = try container.decode(String.self, forKey: .aisleName)
        self.aisleOrder = try container.decodeIfPresent(Int.self, forKey: .aisleOrder) ?? 0
        self.storeId = try container.decode(Int64.self, forKey: .storeId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(aisleId, forKey: .aisleId)
        try container.encode(aisleName, forKey: .aisleName)
        try container.encode(aisleOrder, forKey: .aisleOrder)
        try container.encode(storeId, forKey: .storeId)
    }
}
