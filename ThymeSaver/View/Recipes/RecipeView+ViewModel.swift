import SwiftUI
import GRDB

extension RecipeView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
            
            self.alert = AlertViewModel.init(
                itemName: "Recipe",
                addAction: appDatabase.addRecipe,
                renameAction: appDatabase.renameRecipe,
                deleteAction: appDatabase.deleteRecipe
            )
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                try Recipe.fetchAll(db)
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { recipes in
                self.recipes = recipes
            }
        }
        
        func addRecipe(recipeName: String) {
            appDatabase.addRecipe(recipeName: recipeName)
        }
        
        func deleteRecipe(recipeId: Int) {
            appDatabase.deleteRecipe(recipeId: recipeId)
        }
        
        func renameRecipe(recipeId: Int, newName: String) {
            appDatabase.renameRecipe(recipeId: recipeId, newName: newName)
        }
        
        func toggleRecipePin(recipeId: Int) {
            appDatabase.toggleRecipePin(recipeId: recipeId)
        }
        
        var recipes: [Recipe] = []
        
        var alert: AlertViewModel
    }
}
