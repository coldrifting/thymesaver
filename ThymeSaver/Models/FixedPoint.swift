enum FixedPointConversionError: Error {
    case runtimeError(String)
}

struct FixedPoint {
    let backing: Int
    
    init(_ num: Int) {
        self.backing = num * 1000
    }
    
    init(_ num: Double) {
        self.backing = Int(num * 1000)
    }
    
    init(_ num: String) {
        let regex = /^[a-z\d,]*\.?[a-z\d,]*$/
        
        if (num.wholeMatch(of: regex) == nil) {
            self.backing = 0
            return
        }
        
        var curString: String = "0" + num
        if (!num.contains(".")) {
            curString.append(".0000")
        }
        else {
            curString.append("0000")
        }
        
        let index = curString.firstIndex(of: ".")!
        let secondIndex = curString.index(index, offsetBy: 3)
        curString.remove(at: index)
        curString.insert(".", at: secondIndex)
        
        let finalString = String(curString[curString.startIndex..<secondIndex])
        
        self.backing = Int(finalString) ?? 0
    }
    
    var description: String {
        var asString = String(self.backing)
        if (self.backing < 1000) {
            asString.insert("0", at: asString.startIndex)
        }
        if (self.backing < 100) {
            asString.insert("0", at: asString.startIndex)
        }
        if (self.backing < 10) {
            asString.insert("0", at: asString.startIndex)
        }
        
        let indx = asString.index(asString.endIndex, offsetBy: -3)
        asString.insert(".", at: indx)
        
        return asString
    }
    
    // Returns the fractional part, assuming 3 digits
    var fraction: Int {
        return self.backing % 1000
    }
}

extension Int {
    init(_ fixedPoint: FixedPoint) {
        self = fixedPoint.backing / 1000
    }
}

extension Double {
    init(_ fixedPoint: FixedPoint) {
        self = Double(fixedPoint.backing) / 1000.0
    }
}
