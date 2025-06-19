import SwiftUI
import GRDB

extension RecipeIngredientsView {
    @Observable @MainActor
    class ViewModel {
        private var indexToEntryId: [String:Int] = [:]
        private var indexToItemId: [String:Int] = [:]
        
        private static var checked: [Int: Bool] = [:]
        private static var defaultSection: [Int:Int] = [:]
        
        static func setValue(_ itemId: Int, value: Bool) {
            checked[itemId] = value
        }
        
        static func getValue(_ itemId: Int) -> Bool {
            return checked[itemId] ?? false
        }
        
        static func reset(_ recipeId: Int) {
            checked = [:]
        }
        
        func update() {
            updateRecipeTree(self.recipeItems)
        }
        
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
                    recipes: try RecipeExpanded.getRecipeEntries(db, recipeId: recipeId),
                    items: try Item.fetchAll(db),
                    itemsWithPrep: ItemWithPrep.getAll(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (recipeItems, items, itemsWithPrep) in
                self.items = items
                self.updateRecipeTree(recipeItems)
                self.itemsWithPrep = itemsWithPrep
            }
        }
        
        private func updateRecipeTree(_ recipeItems: RecipeTree) {
            self.usedItemIds = .init()
            self.recipeItems = RecipeTree(
                recipeId: recipeItems.recipeId,
                recipeName: recipeItems.recipeName,
                url: recipeItems.url,
                recipeSections: recipeItems.recipeSections.map { recipeSection in
                    self.usedItemIds[recipeSection.recipeSectionId] = []
                    return RecipeSectionTree(
                        recipeSectionId: recipeSection.recipeSectionId,
                        recipeSectionName: recipeSection.recipeSectionName,
                        items: recipeSection.items.enumerated().map { (index, recipeItem) in
                            self.usedItemIds[recipeSection.recipeSectionId]?.insert(recipeItem.itemId)
                            self.indexToEntryId["\(recipeSection.recipeSectionId),\(index)"] = recipeItem.entryId
                            return ItemTree(
                                itemId: recipeItem.itemId,
                                itemName: recipeItem.itemName,
                                itemTemp: recipeItem.itemTemp,
                                itemPrep: recipeItem.itemPrep,
                                entryId: recipeItem.entryId,
                                amount: recipeItem.amount,
                                isChecked: ViewModel.getValue(recipeItem.itemId.concat(recipeItem.itemPrep?.id ?? 1))
                            )
                        }
                    )
                }
            )
            
            let defaultSectionId: Int = ViewModel.defaultSection[self.recipeId] ?? -1
            if (!self.recipeItems.recipeSections.map { $0.recipeSectionId }.contains(where: { $0 == defaultSectionId })) {
                self.selectedSectionId = self.recipeItems.recipeSections.first?.recipeSectionId ?? defaultSectionId
            }
            
            //self.selectedItemIdBinding.wrappedValue = ViewModel.defaultSection[self.recipeId] ?? -1
        }
        
        /*
        private func updateItemFilter() {
            self.itemsWithPrepFiltered = self.itemsWithPrep.filter {
                !(self.usedItemIds[self.selectedSectionId] ?? []).contains($0.itemId)
                || (self.recipeEntryAndItemId != nil && self.recipeEntryAndItemId?.itemId == $0.itemId)
            }.map { item in
                (id: item.itemId, name: item.itemName)
            }.sorted(by: {$0.name < $1.name })
        }
         */
        
        private(set) var recipeEntryAndItemId: (recipeEntryId: Int, itemId: Int)?
        private(set) var recipeId: Int
        private(set) var recipeName: String
        private var selectedSectionId: Int = -1
        private var usedItemIds: [Int:Set<Int>] = [:]
        private var selectedAmountString: String = "1"
        private var selectedAmountFraction: Fraction = Fraction(1)
        private var selectedAmountUnitType: UnitType = .count
        private(set) var recipeItems: RecipeTree = RecipeTree()
        private(set) var items: [Item] = []
        private(set) var itemsWithPrep: [ItemWithPrep] = []
        //private(set) var itemsWithPrepFiltered: [ItemWithPrep] = []
        //private(set) var itemsFiltered: [(id: Int, name: String)] = []
        
        var selectedOkay: Bool {
            selectedAmountFraction.toDouble() > 0 &&
            selectedSectionId != -1 &&
            selectedItemIdBinding.wrappedValue != nil
        }
        
        // TODO - Use ItemId + ItemPrepId instead of just ItemId
        var selectedSectionIdBinding: Binding<Int> {
            Binding(
                get: { self.selectedSectionId },
                set: {
                    self.selectedSectionId = $0
                    //self.updateItemFilter()
                    //if (!self.itemsFiltered.contains(where: { $0.id == self.selectedItemIdBinding.wrappedValue })) {
                    //    self.selectedItemId = -1
                    //    self.updateItemFilter()
                    //}
                }
            )
        }
        
        var selectedItemId: ItemWithPrep? = nil
        var selectedItemIdBinding: Binding<ItemWithPrep?> {
            Binding(
                get: { self.selectedItemId },
                set: {
                    self.selectedItemId = $0
                    //self.updateItemFilter()
                }
            )
        }
        
        var selectedUnitTypeBinding: Binding<UnitType> {
            Binding(
                get: { self.selectedAmountUnitType },
                set: { self.selectedAmountUnitType = $0 }
            )
        }
        
        var selectedAmountBinding: Binding<String> {
            Binding(
                get: { self.selectedAmountString },
                set: {
                    self.selectedAmountString = $0
                    self.selectedAmountFraction = Fraction($0)
                }
            )
        }
        
        func setupNewItemScreen() {
            self.recipeEntryAndItemId = nil
            self.selectedAmountBinding.wrappedValue = "1"
            self.selectedUnitTypeBinding.wrappedValue = .count
            self.selectedItemIdBinding.wrappedValue = nil
        }
        
        func setupUpdateItemScreen(recipeEntryId: Int, recipeSectionId: Int, type: UnitType, fraction: Fraction, itemId: Int, itemPrepId: Int?) {
            self.recipeEntryAndItemId = (recipeEntryId: recipeEntryId, itemId: itemId)
            self.selectedSectionIdBinding.wrappedValue = recipeSectionId
            self.selectedUnitTypeBinding.wrappedValue = type
            self.selectedAmountBinding.wrappedValue = fraction.decimalString
            self.selectedItemIdBinding.wrappedValue = itemsWithPrep.first(where: { $0.itemId == itemId && $0.itemPrep?.prepId == itemPrepId })
        }
        
        func addRecipeEntry() {
            let frac: Fraction = Fraction(selectedAmountString)
            let amount: Amount = Amount(frac, type: selectedAmountUnitType)
            
            if let currentItemWithPrep = selectedItemIdBinding.wrappedValue {
                appDatabase.addRecipeEntry(
                    recipeSectionId: selectedSectionId,
                    recipeId: self.recipeId,
                    itemId: currentItemWithPrep.itemId,
                    itemPrepId: currentItemWithPrep.itemPrep?.prepId,
                    amount: amount
                )
            }
            
            ViewModel.defaultSection[self.recipeId] = selectedSectionId
            selectedItemIdBinding.wrappedValue = nil
            selectedAmountString = "1"
        }
        
        func updateRecipeEntry(recipeEntryId: Int) {
            let frac: Fraction = Fraction(selectedAmountString)
            let amount: Amount = Amount(frac, type: selectedAmountUnitType)
            
            if let currentItemWithPrep = selectedItemIdBinding.wrappedValue {
                appDatabase.updateRecipeEntry(
                    recipeEntryId: recipeEntryId,
                    itemId: currentItemWithPrep.itemId,
                    itemPrepId: currentItemWithPrep.itemPrep?.prepId,
                    amount: amount
                )
            }
            
            ViewModel.defaultSection[self.recipeId] = selectedSectionId
            selectedItemIdBinding.wrappedValue = nil
            selectedAmountString = "1"
        }
        
        func deleteRecipeEntry(sectionIndex: Int, index: Int) {
            let key: String = "\(sectionIndex),\(index)"
            let recipeEntryId: Int = self.indexToEntryId[key] ?? -1
            appDatabase.deleteRecipeEntry(recipeEntryId: recipeEntryId)
            
            // Auto delete empty sections
            for section in recipeItems.recipeSections {
                if (section.items.isEmpty || section.items.count == 1 && section.items[0].entryId == recipeEntryId) {
                    appDatabase.deleteRecipeSection(recipeId: self.recipeId, recipeSectionId: section.recipeSectionId)
                }
            }
        }
        
        var alert: AlertViewModel
    }
}
