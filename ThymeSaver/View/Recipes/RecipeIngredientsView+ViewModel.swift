import SwiftUI
import GRDB

extension RecipeIngredientsView {
    @Observable @MainActor
    class ViewModelStatic {
        // For each recipe, remember last used section / Entry Checked
        var defaultSection: [Int:Int] = [:]
        var checked: [Int:Bool] = [:]
        
        public static let shared = ViewModelStatic()
    }
    
    @Observable @MainActor
    class ViewModel {
        let staticProperties: ViewModelStatic = ViewModelStatic()
        
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase, recipeId: Int, recipeName: String) {
            self.appDatabase = appDatabase
            self.recipeId = recipeId
            self.recipeName = recipeName
            
            self.alert = AlertViewModel.init(
                itemName: "Recipe Section",
                addAction: { newName in appDatabase.addRecipeSection(recipeSectionName: newName, recipeId: recipeId) },
                renameAction: appDatabase.renameRecipeSection
            )
        }
        
        func observe() {
            let recipeId: Int = self.recipeId
            let observation = ValueObservation.tracking { db in
                (
                    recipeSections: RecipeSect.fetchAll(db, recipeId: recipeId),
                    itemDefaultPreps: ItemWithPrep.getDefaultPreps(db),
                    validItemsPerSection: ItemWithPrep.getValidPerRecipeSection(db, recipeId: recipeId)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (recipeSections, itemDefaultPreps, validItemsPerSection) in
                self.recipeSections = recipeSections
                self.itemDefaultPreps = itemDefaultPreps
                self.validItemsPerSection = validItemsPerSection
            }
        }
        
        // Fields
        private(set) var isNewItemScreen: Bool = false
        
        private(set) var recipeId: Int
        private(set) var recipeName: String
        private(set) var recipeSections: [RecipeSect] = []
        
        private(set) var itemDefaultPreps: [Item:Set<Prep>] = [:]
        
        private(set) var validItemsPerSection: [Int:[Item:Set<Prep>]] = [:]
        
        var alert: AlertViewModel
        
        // Properties
        var selectedOkay: Bool { selectedAmount != nil && selectedSectionId != -1 && selItem != nil }
        var showSectionPicker: Bool { return self.initSelItem == nil && self.recipeSections.count > 1 }
        var enableItemPicker: Bool { return self.initSelItem == nil }
        var enablePrepPicker: Bool { return self.curValidPreps.count > 1 }
        var showPrepPicker: Bool { return (self.itemDefaultPreps[self.selItem ?? Item()] ?? []).count > 1 }
        var lastRecipeSectionId : Int { return self.recipeSections.last?.recipeSectionId ?? -1}
        var defaultSectionId: Int { return
            self.staticProperties.defaultSection[self.recipeId] ?? self.recipeSections.first?.recipeSectionId ?? -1
        }
        
        // Bindings
        var selEntry: RecipeEnt? = nil
        var selPrep: Prep = Prep()
        var selectedAmount: Amount? = nil
        var initSelItem: Item? = nil
        var initSelPrep: Prep = Prep()
        
        private var selectedSectionId: Int = -1
        var selectedSectionIdBinding: Binding<Int> {
            Binding(
                get: { self.selectedSectionId },
                set: {
                    self.selectedSectionId = $0
                    self.validateItem()
                }
            )
        }
        
        var selItem: Item? = nil
        var selItemBinding: Binding<Item?> {
            Binding(
                get: { self.selItem },
                set: { item in
                    self.selItem = item
                    
                    if !self.curValidPreps.contains(where: { prep in prep.prepId == self.selPrep.prepId } ) {
                        self.selPrep = self.curValidPreps.first ?? Prep()
                    }
                    
                    // Reset default units if not set by user
                    if let item = item {
                        if (self.selectedAmount == Amount()) {
                            self.selectedAmount = Amount(1, type: item.defaultUnits)
                        }
                    }
                }
            )
        }
        
        func validateItem() {
            if !self.curValidItems.contains(where: { item in item.itemId == self.selItem?.itemId } ) {
                self.selItemBinding.wrappedValue = nil
                self.selPrep = self.curValidPreps.first ?? Prep()
            }
            
            if !self.curValidPreps.contains(where: { prep in prep.prepId == self.selPrep.prepId } ) {
                self.selPrep = self.curValidPreps.first ?? Prep()
            }
        }
        
        var curValidItems: [Item] {
            if let valid: [Item : Set<Prep>] = self.validItemsPerSection[self.selectedSectionId] {
                var result: Set<Item> = []
                
                for (item, preps) in valid {
                    if (!preps.isEmpty) {
                        result.insert(item)
                    }
                }
                
                return result.sorted(by: {$0.itemName < $1.itemName})
            }
            return []
        }
        
        var curValidPreps: [Prep] {
            if let valid: [Item : Set<Prep>] = self.validItemsPerSection[self.selectedSectionId] {
                if let curItem = self.selItem {
                    var preps: Set<Prep> = valid[curItem] ?? []
                    if (!self.isNewItemScreen) {
                        preps.insert(initSelPrep)
                    }
                    return preps.sorted()
                }
            }
            return []
        }
        
        func setupNewItemScreen() {
            self.isNewItemScreen = true
            self.selEntry = nil
            self.selItem = nil
            self.selPrep = Prep()
            self.initSelPrep = Prep()
            self.selectedAmount = Amount()
            self.selectedSectionId = defaultSectionId
            self.initSelItem = nil
        }
        
        func setupUpdateItemScreen(section: RecipeSect, entry: RecipeEnt) {
            self.isNewItemScreen = false
            self.selEntry = entry
            
            self.selectedAmount = entry.amount
            self.selectedSectionIdBinding.wrappedValue = section.recipeSectionId
            
            self.initSelItem = entry.item
            self.initSelPrep = entry.prep
            
            self.selItem = entry.item
            self.selPrep = entry.prep
        }
        
        func addOrUpdateRecipeEntry() {
            if let entry = self.selEntry {
                updateRecipeEntry(recipeEntryId: entry.recipeEntryId)
            }
            else {
                addRecipeEntry()
            }
        }
        
        func addRecipeEntry() {
            if let item = selItem, let amount = self.selectedAmount {
                appDatabase.addRecipeEntry(
                    recipeSectionId: selectedSectionId,
                    recipeId: self.recipeId,
                    itemId: item.itemId,
                    prepId: selPrep.prepId,
                    amount: amount
                )
            }
            
            staticProperties.defaultSection[self.recipeId] = selectedSectionId
            //self.selItem = nil
            //self.selPrep = Prep()
            //self.selectedAmount = nil
        }
        
        func updateRecipeEntry(recipeEntryId: Int) {
            let prepId: Int = self.selPrep.prepId
            if let currentItemWithPrep = self.selItem, let amount = self.selectedAmount {
                appDatabase.updateRecipeEntry(
                    recipeEntryId: recipeEntryId,
                    itemId: currentItemWithPrep.itemId,
                    prepId: prepId,
                    amount: amount
                )
            }
            
            //self.staticProperties.defaultSection[self.recipeId] = selectedSectionId
            //self.selectedAmount = nil
            //self.initSelItem = nil
        }
        
        func deleteRecipeEntry(_ entry: RecipeEnt) {
            self.appDatabase.deleteRecipeEntry(recipeEntryId: entry.recipeEntryId)
            
            // Auto delete empty sections
            for section in recipeSections {
                if (section.entries.isEmpty || section.entries.count == 1 && section.entries[0].recipeEntryId == entry.recipeEntryId) {
                    self.appDatabase.deleteRecipeSection(recipeId: self.recipeId, recipeSectionId: section.recipeSectionId)
                }
            }
        }
    }
}
