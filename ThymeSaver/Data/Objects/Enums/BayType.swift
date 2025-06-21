import GRDB

enum BayType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible, DatabaseValueConvertible {
    case start = "Start"
    case middle = "Middle"
    case end = "End"
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue.capitalized
    }
}
