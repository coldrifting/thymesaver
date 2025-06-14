import Foundation
import GRDB

enum ItemTemp: String, Codable, CaseIterable, Comparable, Identifiable, CustomStringConvertible, DatabaseValueConvertible {
    case ambient = "Ambient"
    case chilled = "Chilled"
    case frozen = "Frozen"
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue.capitalized
    }
    
    static func < (lhs: ItemTemp, rhs: ItemTemp) -> Bool {
        if (lhs == .ambient && rhs != .ambient) {
            return true
        }
        
        // Frozen always more than
        if (lhs == .chilled && rhs == .frozen) {
            return true
        }
        
        return false
    }
    
}
