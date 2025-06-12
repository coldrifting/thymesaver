import Foundation
import SwiftData

enum ItemTemp: String, Codable, CaseIterable {
    case ambient = "Ambient"
    case chilled = "Chilled"
    case frozen = "Frozen"
}
