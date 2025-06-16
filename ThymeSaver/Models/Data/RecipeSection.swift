import Foundation
import GRDB

struct RecipeSection: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable {
    var recipeSectionId: Int
    var recipeSectionName: String
    var recipeSectionOrder: Int = -1
    var recipeId: Int
    
    var id: Int { recipeSectionId }
    
    enum Columns {
        static let recipeSectionId = Column(CodingKeys.recipeSectionId)
        static let recipeSectionName = Column(CodingKeys.recipeSectionName)
        static let recipeSectionOrder = Column(CodingKeys.recipeSectionOrder)
        static let recipeId = Column(CodingKeys.recipeId)
    }
    
    static var databaseTableName: String = "RecipeSections"
}

struct RecipeSectionInsert: Codable, FetchableRecord, PersistableRecord {
    var recipeSectionName: String
    var recipeSectionOrder: Int = -1
    var recipeId: Int
    
    static var databaseTableName: String { RecipeSection.databaseTableName }
}
