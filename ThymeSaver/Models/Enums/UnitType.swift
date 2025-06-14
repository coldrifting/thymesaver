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
}
