import SwiftUI
import GRDB

extension RecipeView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
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
            try? appDatabase.addRecipe(recipeName: recipeName)
        }
        
        func deleteRecipe(recipeId: Int) {
            // TODO: - Check delete constraints
            
            try? appDatabase.deleteRecipe(recipeId: recipeId)
        }
        
        func renameRecipe(recipeId: Int, newName: String) {
            try? appDatabase.renameRecipe(recipeId: recipeId, newName: newName)
        }
        
        var recipes: [Recipe] = []
        
        // MARK: - Alerts
        private(set) var alertType: AlertType = AlertType.none
        private(set) var alertId: Int = -1
        
        private(set) var alertTitle: String = ""
        private(set) var alertMessage: String = ""
        private(set) var alertConfirmText: String = ""
        private(set) var alertDismissText: String = "Cancel"
        private(set) var alertPlaceholder: String = "Recipe Name"
        
        private(set) var alertTextEntry: String = ""
        
        var alertTextBinding: Binding<String> {
            Binding(
                get: { self.alertTextEntry },
                set: { self.alertTextEntry = $0 }
            )
        }
        
        func queueAddItemAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .add
            alertTitle = "Add Item Preperation"
            alertMessage = "Please enter a name for the new Recipe"
            alertConfirmText = "Add"
        }
        
        func queueRenameItemAlert(itemId: Int, itemName: String) {
            alertId = itemId
            alertTextEntry = itemName
            alertType = .rename
            alertTitle = "Rename Recipe"
            alertMessage = "Please enter a new name for this Recipe"
            alertConfirmText = "Rename"
        }
        
        func queueDeleteItemAlert(itemId: Int, itemsInUse: [String]) {
            let itemsInUseString: String = itemsInUse.count > 8
            ? itemsInUse.prefix(8).joined(separator: "\n") + "\n..."
            : itemsInUse.joined(separator: "\n")
            
            alertId = itemId
            alertTextEntry = ""
            alertType = .delete
            alertTitle = "Delete Recipe"
            alertMessage = "The following items are in use:\n \(itemsInUseString)"
            alertConfirmText = "Delete"
        }
        
        func dismissAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .none
        }
    }
}
