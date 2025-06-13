import Foundation
import GRDB

enum ItemTemp: String, Codable, CaseIterable, Identifiable, CustomStringConvertible, DatabaseValueConvertible {
    case ambient = "Ambient"
    case chilled = "Chilled"
    case frozen = "Frozen"
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue.capitalized
    }
}
