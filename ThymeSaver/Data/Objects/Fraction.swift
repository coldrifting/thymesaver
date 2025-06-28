struct Fraction: Codable, Identifiable, Hashable, CustomStringConvertible {
    var num: Int
    var dem: Int = 1
    
    var id: Int { num.concat(dem) }
    
    var description: String { Fraction.getFractionChar(fraction: self) }
    
    var decimalString: String {
        let test = Int((Double(self.num) * 1000.0) / Double(self.dem))
        return String(Double(test) / 1000.0)
    }
    
    init(_ input: FixedPoint) {
        let whole: Int = Int(input)
        let fraction = input.fraction
        
        if (fraction == 0) {
            self.num = whole
            return
        }
        
        // Special handling for 3rds and 6ths
        switch fraction {
        case 160: fallthrough
        case 166: fallthrough
        case 167:
            self.num = (whole * 6) + 1
            self.dem = 6
            return
            
        case 330: fallthrough
        case 333: fallthrough
        case 334:
            self.num = (whole * 3) + 1
            self.dem = 3
            return
            
        case 660: fallthrough
        case 666: fallthrough
        case 667:
            self.num = (whole * 3) + 2
            self.dem = 3
            return
            
        case 830: fallthrough
        case 833: fallthrough
        case 834:
            self.num = (whole * 6) + 5
            self.dem = 6
            return
            
        default:
            break
        }
        
        for divisor in stride(from: 2, through: 16, by: 1) {
            if ((fraction * divisor % 1000) == 0) {
                self.num = (whole * divisor) + ((fraction * divisor) / 1000)
                self.dem = divisor
                return
            }
        }
        
        // Fallback
        self.num = (whole * 1000) + fraction
        self.dem = 1000
    }
    
    init(_ string: String) {
        let fixedPoint: FixedPoint = FixedPoint(string)
        self = Fraction(fixedPoint)
    }
    
    init(_ num: Int, dem: Int) {
        self.num = num
        self.dem = dem
    }
    
    init(_ num: Int) {
        self.num = num
    }
    
    // Serialization
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringVal = try container.decode(String.self)
        
        let arr: [String] = stringVal.split(separator: "/").map(String.init)
        
        self.num = Int(arr[0]) ?? 1
        self.dem = arr.count > 1 ? Int(arr[1]) ?? 1 : 1
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(num)/\(dem)")
    }
    
    // Formatting
    func isPlural() -> Bool {
        if (Float(num) / Float(dem) > 1.0) {
            return true
        }
        return Fraction.getFractionChar(fraction: self).contains(".")
    }
    
    private static func getFractionChar(fraction: Fraction) -> String {
        if (fraction.num > fraction.dem) {
            let whole: Int = fraction.num / fraction.dem
            let partial: Int = fraction.num % fraction.dem
            
            if (partial == 0) {
                return whole.description
            }
            
            let output: String = whole.description + " " + Fraction.getFractionChar(fraction: Fraction(partial, dem: fraction.dem))
            
            return output.replacingOccurrences(of: " 0.", with: ".")
        }
        
        switch "\(fraction.num)/\(fraction.dem)" {
        case "1/2": return "½"

        case "1/3": fallthrough
        case "33/100": fallthrough
        case "333/1000": return "⅓"
            
        case "2/3": fallthrough
        case "66/100": fallthrough
        case "666/1000": return "⅔"
            
        case "1/4": return "¼"
        case "3/4": return "¾"

        case "1/5": return "⅕"
        case "2/5": return "⅖"
        case "3/5": return "⅗"
        case "4/5": return "⅘"

        case "1/6": return "⅙"
        case "5/6": return "⅚"

        case "1/8": return "⅛"
        case "3/8": return "⅜"
        case "5/8": return "⅝"
        case "7/8": return "⅞"
            
        default:
            let test = String(format: "%g", Float(fraction.num) / Float(fraction.dem))
            return String(test.prefix(4))
        }
    }
    
    // Math Functions
    func toInt() -> Int {
        num / dem;
    }
    
    func toDouble() -> Double {
        Double(num) / Double(dem);
    }
    
    static func + (left: Fraction, right: Fraction) -> Fraction {
        if (left.dem == right.dem) {
            return Fraction(left.num + right.num, dem: left.dem).simplify()
        }
        
        let lcd = left.dem * right.dem
        let leftMult = lcd / left.dem
        let rightMult = lcd / right.dem
        
        return Fraction(left.num * leftMult + right.num * rightMult, dem: lcd).simplify()
    }
    
    static func * (left: Fraction, right: Fraction) -> Fraction {
        return Fraction(left.num * right.num, dem: left.dem * right.dem).simplify()
    }
    
    static func * (left: Fraction, right: Int) -> Fraction {
        return Fraction(left.num * right, dem: left.dem).simplify()
    }
    
    static func / (left: Fraction, right: Int) -> Fraction {
        return Fraction(left.num, dem: left.dem * right).simplify()
    }
    
    private func simplify() -> Fraction {
        for div in stride(from: dem, through: 2, by: -1) {
            if (num % div == 0 && dem % div == 0) {
                return Fraction(num / div, dem: dem / div)
            }
        }
        return self
    }
}
