import SwiftUI
import GRDB

extension RecipeStepsView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase, recipeId: Int, recipeName: String) {
            self.appDatabase = appDatabase
            self.recipeId = recipeId
            self.recipeName = recipeName
        }
        
        func observe() {
            let recipeId: Int = self.recipeId
            let observation = ValueObservation.tracking { db in
                (
                    recipe: try Recipe.fetchOne(db, key: recipeId),
                    steps: try RecipeStep.filter{ $0.recipeId == recipeId }.order(\.recipeStepOrder).fetchAll(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (recipe, steps) in
                self.recipe = recipe
                self.steps = steps
            }
        }
        
        let recipeId: Int
        let recipeName: String
        
        var recipe: Recipe?
        var steps: [RecipeStep] = []
        
        var recipeStepId: Int? = nil
        private(set) var selectedOkay: Bool = false
        
        var recipeUrl: Binding<String> {
            Binding(
                get: { self.recipe?.url ?? "" },
                set: { value in self.appDatabase.updateRecipeUrl(recipeId: self.recipeId, newUrl: value) }
            )
        }
        
        private var _recipeStepContent: String = ""
        var recipeStepContent: Binding<String> {
            Binding(
                get: { self._recipeStepContent },
                set: { value in
                    self._recipeStepContent = value
                    self.selectedOkay = !value.trim().isEmpty
                }
            )
        }
        
        func addOrUpdateStep() {
            let content = self._recipeStepContent.trim()
            let isImage: Bool = content.lowercased().hasPrefix("http")
            let contentFinal: String = !isImage ? content : content.replacingOccurrences(of: "^https://", with: "https://", options: [.regularExpression, .caseInsensitive])
            
            if let recipeStepId = self.recipeStepId {
                appDatabase.updateRecipeStep(recipeStepId: recipeStepId, newText: contentFinal, isImage: isImage)
            } else {
                appDatabase.addRecipeStep(recipeId: self.recipeId, recipeStepContent: contentFinal, isImage: isImage)
            }
        }
        
        func setStepIndex(recipeStepId: Int, newIndex: Int) {
            appDatabase.setRecipeStepIndex(recipeStepId: recipeStepId, newIndex: newIndex)
        }
        
        func deleteStep(recipeStepId: Int) {
            appDatabase.deleteRecipeStep(recipeStepId: recipeStepId)
        }
    }
}
