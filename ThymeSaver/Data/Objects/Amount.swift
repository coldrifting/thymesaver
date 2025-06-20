import GRDB

struct Amount: Codable, Identifiable, Hashable, DatabaseValueConvertible, CustomStringConvertible {
    var fraction: Fraction
    var type: UnitType
    
    var id: Int { fraction.id.concat(type.hashValue) }
    
    var description: String { "\(fraction) \(type.getAbbreviation(fraction.isPlural()))" }
    
    init() {
        self.fraction = Fraction(1)
        self.type = UnitType.count
    }
    
    init(_ fraction: Fraction, type: UnitType) {
        self.fraction = fraction
        self.type = type
    }
    
    init(_ value: Int, type: UnitType) {
        self.fraction = Fraction(value)
        self.type = type
    }
    
    func simplify() -> Amount {
        if (self.type == UnitType.volumeTeaspoons && fraction.toInt() >= 3) {
            return Amount(fraction / 3, type: .volumeTablespoons)
        }
        
        if (self.type == UnitType.volumeTablespoons && fraction.toInt() >= 16) {
            return Amount(fraction / 16, type: .volumeCups)
        }
        
        return self
    }
    
    static func + (left: Amount, right: Amount) -> Amount {
        if (left.type == right.type) {
            return Amount(left.fraction + right.fraction, type: left.type).simplify()
        }
        
        let leftStr = left.type.description
        let rightStr = right.type.description
        
        let index = leftStr.startIndex
        let index2 = leftStr.index(index, offsetBy: 3)
        
        if (String(leftStr[index..<index2]) != String(rightStr[index..<index2])) {
            return Amount(0, type: .count) // Error
        }
        
        let divisor: Int
        let selectedType: UnitType
        if (left.type.getUnits() > right.type.getUnits()) {
            divisor = left.type.getUnits()
            selectedType = left.type
        }
        else {
            divisor = right.type.getUnits()
            selectedType = right.type
        }
            
        let newFraction = ((left.fraction * left.type.getUnits()) + (right.fraction * right.type.getUnits())) / divisor
        return Amount(newFraction, type: selectedType)
    }
}
