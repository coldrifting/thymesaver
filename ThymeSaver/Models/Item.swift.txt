import Foundation
import SwiftData

@Model
final class Item: Codable, Comparable {
    private(set) var uuid: UUID
    var name: String
    var temp: ItemTemp
    var defaultUnits: UnitType
    
    init(name: String, temp: ItemTemp = .ambient, defaultUnits: UnitType = .count, uuid: UUID? = nil) {
        self.name = name
        self.temp = temp
        self.defaultUnits = defaultUnits
        self.uuid = uuid ?? UUID()
    }
    
    // Serialization
    enum CodingKeys: CodingKey {
        case itemId
        case itemName
        case itemTemp
        case defaultUnits
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try UUID.init(number: container.decode(Int64.self, forKey: .itemId))
        self.name = try container.decode(String.self, forKey: .itemName)
        self.temp = try container.decodeIfPresent(ItemTemp.self, forKey: .itemTemp) ?? ItemTemp.ambient
        self.defaultUnits = try container.decodeIfPresent(UnitType.self, forKey: .defaultUnits) ?? UnitType.count
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .itemId)
        try container.encode(name, forKey: .itemName)
        try container.encode(temp, forKey: .itemTemp)
        try container.encode(defaultUnits, forKey: .defaultUnits)
    }
    
    // Sorting
    static func == (lhs: Item, rhs: Item) -> Bool {
      return (lhs.name, lhs.id) == (rhs.name, rhs.id)
    }
    
    static func < (lhs: Item, rhs: Item) -> Bool {
        return (lhs.name.lowercased(), lhs.id) < (rhs.name.lowercased(), rhs.id)
    }
}
