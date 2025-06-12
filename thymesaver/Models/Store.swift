import Foundation
import SwiftData

@Model
final class Store: Codable, Comparable {
    private(set) var uuid: UUID
    var name: String
    var selected: Bool
    var aisles: [Aisle]
    
    init(name: String, uuid: UUID? = nil, selected: Bool = false) {
        self.name = name
        self.uuid = uuid ?? UUID()
        self.selected = selected
        self.aisles = []
    }
    
    enum CodingKeys: CodingKey {
        case storeId
        case storeName
        case selected
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try UUID.init(number: container.decode(Int64.self, forKey: .storeId))
        self.name = try container.decode(String.self, forKey: .storeName)
        self.selected = try container.decodeIfPresent(Bool.self, forKey: .selected) ?? false
        self.aisles = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .storeId)
        try container.encode(name, forKey: .storeName)
        try container.encode(selected, forKey: .selected)
    }
    
    static func == (lhs: Store, rhs: Store) -> Bool {
      return (lhs.name, lhs.id) == (rhs.name, rhs.id)
    }
    
    static func < (lhs: Store, rhs: Store) -> Bool {
        return (lhs.name.lowercased(), lhs.id) < (rhs.name.lowercased(), rhs.id)
    }
}
