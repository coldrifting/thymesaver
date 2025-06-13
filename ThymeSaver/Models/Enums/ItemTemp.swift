import Foundation

enum ItemTemp: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case ambient
    case chilled
    case frozen
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue.capitalized
    }
}
