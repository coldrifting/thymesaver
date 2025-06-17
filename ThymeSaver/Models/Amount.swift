import GRDB

struct Amount: Codable, Identifiable, Hashable, DatabaseValueConvertible, CustomStringConvertible {
    var fraction: Fraction
    var type: UnitType
    
    var id: Int { fraction.id.concat(type.hashValue) }
    
    var description: String { "\(fraction) \(type.getAbbreviation(fraction.isPlural()))" }
    
    init(_ fraction: Fraction, type: UnitType) {
        self.fraction = fraction
        self.type = type
    }
    
    init(_ value: Int, type: UnitType) {
        self.fraction = Fraction(value)
        self.type = type
    }
    
    init(_ value: Double, type: UnitType) {
        self.fraction = Fraction(value)
        self.type = type
    }
    
    static func + (left: Amount, right: Amount) -> Amount {
        if (left.type == right.type) {
            return Amount(left.fraction + right.fraction, type: left.type)
        }
        
        // TODO: -
        return Amount(0, type: .count)
    }
}
