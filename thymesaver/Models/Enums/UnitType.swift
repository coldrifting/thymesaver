import Foundation
import SwiftData

enum UnitType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
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
        switch self {
        case .count:
            return "Count"
        case .volumeTeaspoons:
            return "Teaspoons"
        case .volumeTablespoons:
            return "Tablespoons"
        case .volumeOunces:
            return "Ounces"
        case .volumeCups:
            return "Cups"
        case .volumeQuarts:
            return "Quarts"
        case .volumePints:
            return "Pints"
        case .volumeGallons:
            return "Gallons"
        case .weightOunces:
            return "Ounces (#)"
        case .weightPounds:
            return "Pounds"
        }
    }
}
