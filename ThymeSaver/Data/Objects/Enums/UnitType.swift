import Foundation
import GRDB

enum UnitType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible, DatabaseValueConvertible {
    case count = "Count"
    case volumeTeaspoons = "VolumeTeaspoons"
    case volumeTablespoons = "VolumeTablespoons"
    case volumeOunces = "VolumeOunces"
    case volumeCups = "VolumeCups"
    case volumeQuarts = "VolumeQuarts"
    case volumePints = "VolumePints"
    case volumeGallons = "VolumeGallons"
    case weightOunces = "WeightOunces"
    case weightPounds = "WeightPounds"
    
    var id: Self { self }
    
    var description: String {
        return self.rawValue
            .replacingOccurrences(of: "WeightOunces", with: "Ounces (#)")
            .replacingOccurrences(of: "Volume", with: "")
            .replacingOccurrences(of: "Weight", with: "")
    }
    
    func getAbbreviation(_ isPlural: Bool = false) -> String {
        return switch self {
        case .count:
            "ea."
        case .volumeTeaspoons:
            "tsp"
        case .volumeTablespoons:
            "Tbsp"
        case .volumeOunces:
            "oz"
        case .volumeCups:
            isPlural ? "cups" : "cup"
        case .volumePints:
            "pt"
        case .volumeQuarts:
            "qt"
        case .volumeGallons:
            "gal"
        case .weightOunces:
            "oz"
        case .weightPounds:
            isPlural ? "lbs" : "lb"
        }
    }
    
    func getUnits() -> Int {
        return switch self {
        case .count:
            1
        case .volumeTeaspoons:
            1
        case .volumeTablespoons:
            3
        case .volumeOunces:
            6
        case .volumeCups:
            48
        case .volumePints:
            96
        case .volumeQuarts:
            192
        case .volumeGallons:
            768
        case .weightOunces:
            1
        case .weightPounds:
            16
        }
    }
}
