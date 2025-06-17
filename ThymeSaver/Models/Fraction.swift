struct Fraction: Codable, Identifiable, Hashable, CustomStringConvertible {
    var num: Int
    var dem: Int = 1
    
    var id: Int { num.concat(dem) }
    
    var description: String { Fraction.getFractionChar(fraction: self) }
    
    var decimalString: String {
        let test = Int((Double(self.num) * 1000.0) / Double(self.dem))
        return String(Double(test) / 1000.0)
    }
    
    init(_ string: String) {
        if let value: Float = Float(string) {
            
            let whole: Int = Int(value)
            let partialFraction: Float = value - Float(whole)
            
            switch string {
            case _ where string.hasSuffix(".16"): fallthrough
            case _ where string.hasSuffix(".167"): fallthrough
            case _ where string.hasSuffix(".166"):
                self.num = (whole * 6) + 1
                self.dem = 6
                return
                
            case _ where string.hasSuffix(".33"): fallthrough
            case _ where string.hasSuffix(".334"): fallthrough
            case _ where string.hasSuffix(".333"):
                self.num = (whole * 3) + 1
                self.dem = 3
                return
                
            case _ where string.hasSuffix(".66"): fallthrough
            case _ where string.hasSuffix(".667"): fallthrough
            case _ where string.hasSuffix(".666"):
                self.num = (whole * 3) + 2
                self.dem = 3
                return
                
            case _ where string.hasSuffix(".83"): fallthrough
            case _ where string.hasSuffix(".834"): fallthrough
            case _ where string.hasSuffix(".833"):
                self.num = (whole * 6) + 5
                self.dem = 6
                return
                
            default:
                break
            }
            
            for i in stride(from: 2, through: 16, by: 1) {
                let rounded: Int = Int(partialFraction * Float(i) * 1000.0)
                if (rounded % 1000 == 0) {
                    self.num = Int((Float(whole) + Float(partialFraction) * Float(i)))
                    self.dem = i
                    return
                }
            }
            
            // Fallback
            self.num = Int(value * 1000.0)
            self.dem = 1000
            return
        }
        self.num = -1
    }
    
    init(_ num: Int, dem: Int) {
        self.num = num
        self.dem = dem
    }
    
    init(_ num: Int) {
        self.num = num
    }
    
    init(_ num: Double) {
        // TODO: - Convert to fraction instead of truncating
        self.num = Int(num)
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
            
            return whole.description + " " + Fraction.getFractionChar(fraction: Fraction(partial, dem: fraction.dem))
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
            return Fraction(left.num + right.num, dem: left.dem)
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
        for div in dem...2 {
            if (num % div == 0 && dem % div == 0) {
                return Fraction(num / div, dem: dem / div)
            }
        }
        return self
    }
}
