import Foundation
import SwiftData

@Model
final class Store {
    private(set) var id = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
}
