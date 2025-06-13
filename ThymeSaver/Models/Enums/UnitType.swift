import Foundation

enum UnitType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case count
    case volumeTeaspoons
    case volumeTablespoons
    case volumeOunces
    case volumeCups
    case volumeQuarts
    case volumePints
    case volumeGallons
    case weightOunces
    case weightPounds
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue
            .replacingOccurrences(of: "WeightOunces", with: "Ounces (#)")
            .replacingOccurrences(of: "Volume", with: "")
            .replacingOccurrences(of: "Weight", with: "")
    }
}
