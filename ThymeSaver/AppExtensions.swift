import SwiftUI

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    func chop(_ maxChars: Int = 58) -> String {
        let maxChars = self.count < maxChars ? self.count : maxChars
        let endIndex: String.Index = self.index(self.startIndex, offsetBy: maxChars)
        let finalString = self[..<endIndex]
        if (finalString.count < self.count) {
            return "\(finalString)".trim() + "..."
        }
        return finalString.description
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    
    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
}

extension UUID {
    init(number: Int64) {
        var number = number
        let numberData = Data(bytes: &number, count: MemoryLayout<Int64>.size)
        
        let bytes = [UInt8](numberData)
        
        let tuple: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0,
                             bytes[0], bytes[1], bytes[2], bytes[3],
                             bytes[4], bytes[5], bytes[6], bytes[7])
        
        self.init(uuid: tuple)
    }
}

extension Int {
    // Cantor pairing function
    func concat(_ other: Int) -> Int {
        return (self + other) * (self + other + 1) / 2 + self;
    }
}
