import SwiftUI
import GRDB

extension CartView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                (
                    items: try Item.getItems(db),
                    recipes: try Recipe.fetchAll(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (items, recipes) in
                self.allItems = items
                self.allRecipes = recipes
                
                self.selectedRecipes = recipes.filter { recipe in recipe.cartAmount > 0 }
                self.selectedItems = items.filter { item in item.cartAmount?.fraction.toDouble() ?? 0 > 0 }
            }
        }
        
        private(set) var allItems: [Item] = []
        private(set) var allRecipes: [Recipe] = []
        
        private(set) var selectedRecipes: [Recipe] = []
        var validRecipes: [Recipe] {
            allRecipes.filter { recipe in !selectedRecipes.map{ $0.recipeId}.contains(recipe.recipeId) }
        }
        
        private(set) var selectedItems: [Item] = []
        var validItems: [Item] {
            allItems.filter { item in !selectedItems.map { $0.itemId}.contains(item.itemId) }
        }
        
        private var _showBottomSheet: Bool = false
        var showBottomSheet: Binding<Bool> {
            Binding (
                get: { self._showBottomSheet },
                set: { value in
                    self._showBottomSheet = value
                    if (!value) {
                        self.reset()
                    }
                }
            )
        }
        
        func reset() {
            self._selectedItemAmount = nil
            self._selectedRecipeQuantity = 1
            self._selectedItemToAdd = nil
            self._selectedRecipeToAdd = nil
            self.addUpdateButtonEnabled = false
        }
        
        var addUpdateButtonText: String = "Add Recipe"
        
        var _isSelectionInRecipeMode: Bool = true
        var isSelectionInRecipeMode: Binding<Bool> {
            Binding (
                get: { self._isSelectionInRecipeMode },
                set: { value in
                    self._isSelectionInRecipeMode = value
                    self.addUpdateButtonText = value ? "Add Recipe" : "Add Item"
                }
            )
        }
        
        var _selectedRecipeQuantity: Int = 1
        var selectedRecipeQuantity: Binding<Int> {
            Binding (
                get: { self._selectedRecipeQuantity },
                set: { value in self._selectedRecipeQuantity = value >= 1 ? value : 1 }
            )
        }
        
        var _selectedRecipeToAdd: Recipe? = nil
        var selectedRecipeToAdd: Binding<Recipe?> {
            Binding (
                get: { self._selectedRecipeToAdd },
                set: { value in
                    self._selectedRecipeToAdd = value
                    self.validate(isRecipe: true)
                }
            )
        }
        
        var _selectedItemToAdd: Item? = nil
        var selectedItemToAdd: Binding<Item?> {
            Binding (
                get: { self._selectedItemToAdd },
                set: { value in
                    self._selectedItemToAdd = value
                    if (self._selectedItemAmount == nil) {
                        self._selectedItemAmount = self.getAmountOrDefault(item: value)
                    }
                    self.validate(isRecipe: false)
                }
            )
        }
        
        func getAmountOrDefault(item: Item?) -> Amount? {
            if let item = item {
                return item.cartAmount ?? Amount()
            }
            return Amount()
        }
        
        var _selectedItemAmount: Amount? = nil
        var selectedItemAmount: Binding<Amount?>  {
            Binding(
                get: { self._selectedItemAmount },
                set: { value in
                    self._selectedItemAmount = value
                    self.validate(isRecipe: false)
                }
            )
        }
        
        func validate(isRecipe: Bool) {
            if (isRecipe) {
                self.addUpdateButtonEnabled = self._selectedRecipeToAdd != nil
            }
            else {
                self.addUpdateButtonEnabled = self._selectedItemToAdd != nil && self._selectedItemAmount != nil
            }
        }
        
        var addUpdateButtonEnabled: Bool = false
        var inUpdateMode: Bool = false
        var selectionUnits: UnitType = UnitType.count
        
        func addOrUpdateRecipeOrItem() {
            
            if (self.isSelectionInRecipeMode.wrappedValue) {
                if let recipeId = self._selectedRecipeToAdd?.recipeId {
                    self.appDatabase.updateRecipeCartAmount(
                        recipeId: recipeId,
                        newAmount: self._selectedRecipeQuantity
                    )
                }
            }
            else {
                if let itemId = self._selectedItemToAdd?.itemId, let amount = self._selectedItemAmount  {
                    self.appDatabase.updateItemCartAmount(
                        itemId: itemId,
                        cartAmount: amount
                    )
                }
            }
            
            self.showBottomSheet.wrappedValue = false
        }
        
        func queueAddRecipeOrItem() {
            self.addUpdateButtonText = "Add Recipe"
            self.inUpdateMode = false
            self.showBottomSheet.wrappedValue = true
        }
        
        func queueUpdateRecipe(recipe: Recipe) {
            self.selectedRecipeQuantity.wrappedValue = recipe.cartAmount
            self.addUpdateButtonText = "Update Quantity"
            self.inUpdateMode = true
            self.isSelectionInRecipeMode.wrappedValue = true
            self.selectedRecipeToAdd.wrappedValue = recipe
            self.showBottomSheet.wrappedValue = true
        }
        
        func queueUpdateItem(item: Item) {
            self.selectedItemAmount.wrappedValue = item.cartAmount
            self.addUpdateButtonText = "Update Quantity"
            self.inUpdateMode = true
            self.isSelectionInRecipeMode.wrappedValue = false
            self.selectedItemToAdd.wrappedValue = item
            self.showBottomSheet.wrappedValue = true
        }
        
        func removeFromCart(recipeId: Int) {
            self.appDatabase.updateRecipeCartAmount(recipeId: recipeId, newAmount: 0)
        }
        
        func removeFromCart(itemId: Int) {
            self.appDatabase.updateItemCartAmount(itemId: itemId)
        }
    }
}
