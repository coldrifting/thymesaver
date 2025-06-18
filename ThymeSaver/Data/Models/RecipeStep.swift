import Foundation
import GRDB

struct RecipeStep: Codable, Identifiable, FetchableRecord, PersistableRecord, Hashable {
    var recipeStepId: Int
    var recipeStepContent: String
    var recipeStepOrder: Int
    var isImage: Bool
    var recipeId: Int
    
    var id: Int { recipeStepId }
    
    enum Columns {
        static let recipeStepId = Column(CodingKeys.recipeStepId)
        static let recipeStepOrder = Column(CodingKeys.recipeStepOrder)
        static let recipeStepContent = Column(CodingKeys.recipeStepContent)
        static let isImage = Column(CodingKeys.isImage)
        static let recipeId = Column(CodingKeys.recipeId)
    }
    
    static var databaseTableName: String = "RecipeSteps"
}

struct RecipeStepInsert: Codable, FetchableRecord, PersistableRecord {
    var recipeStepOrder: Int
    var recipeStepContent: String
    var isImage: Bool
    var recipeId: Int
    
    static var databaseTableName: String { RecipeStep.databaseTableName }
}

extension AppDatabase {
    func addRecipeStep(recipeId: Int, recipeStepContent: String, recipeStepOrder: Int? = nil, isImage: Bool = false) {
        try? dbWriter.write { db in
            let sqlMax: String = "SELECT Max(recipeStepOrder) + 1 FROM RecipeSteps WHERE recipeId = \(recipeId)"
            let stepOrder: Int = recipeStepOrder ?? (try? Int.fetchOne(db, sql: sqlMax)) ?? 0
            let recipeStep = RecipeStepInsert(
                recipeStepOrder: stepOrder,
                recipeStepContent: recipeStepContent,
                isImage: isImage,
                recipeId: recipeId
            )
            try recipeStep.insert(db)
        }
    }
    
    func updateRecipeStep(recipeStepId: Int, newText: String, isImage: Bool) {
        try? dbWriter.write { db in
            var recipeStep = try RecipeStep.find(db, key: recipeStepId)
            recipeStep.recipeStepContent = newText
            recipeStep.isImage = isImage
            try recipeStep.update(db, columns: [RecipeStep.Columns.recipeStepContent, RecipeStep.Columns.isImage])
        }
    }
    
    func deleteRecipeStep(recipeStepId: Int) {
        try? dbWriter.write { db in
            _ = try RecipeStep.deleteOne(db, key: recipeStepId)
        }
    }
    
    func setRecipeStepIndex(recipeStepId: Int, newIndex: Int) {
        try? dbWriter.write { db in
            var recipeStep = try RecipeStep.find(db, key: recipeStepId)
            recipeStep.recipeStepOrder = newIndex
            try recipeStep.update(db, columns: [RecipeStep.Columns.recipeStepOrder])
        }
    }
}
