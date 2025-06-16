import Foundation

enum AlertType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case none
    case add
    case rename
    case delete
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue.capitalized
    }
}
