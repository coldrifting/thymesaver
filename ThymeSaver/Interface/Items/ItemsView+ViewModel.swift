import SwiftUI
import GRDB

extension ItemsView {
    enum SectionSplitType: CaseIterable {
        case none
        case temp
        case aisle
    }
    
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe(filterText: String) {
            let observation = ValueObservation.tracking { db in
                try ItemExpanded.getItemsFiltered(db, itemNameFilter: filterText)
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { items in
                self.itemsWithAisleInfo = self.splitItemsBySection(items: items)
            }
        }
        
        private(set) var itemsWithAisleInfo: [(section: String, items: [ItemExpanded])] = []
        private(set) var sectionSplitType: SectionSplitType = .none
        
        func splitItemsBySection(items: [ItemExpanded]) -> [(section: String, items: [ItemExpanded])] {
            switch self.sectionSplitType {
            case .none:
                return [(section: "All Items by Name", items: items)]
            case .temp:
                return Dictionary(grouping: items, by: { $0.itemTemp} )
                    .sorted(by: { $0.key < $1.key })
                    .map{ ("\($0.key)", $0.value) }
            case .aisle:
                return Dictionary(grouping: items, by: { $0.aisleId} )
                    .sorted(by: { $0.value.first?.aisleOrder ?? Int.max < $1.value.first?.aisleOrder ?? Int.max })
                    .map{ ("\($0.value.first?.aisleName ?? "No Aisle Assigned")", $0.value) }
            }
        }
        
        func cycleSectionSplitType() {
            switch sectionSplitType {
            case .none:
                sectionSplitType = .temp
            case .temp:
                sectionSplitType = .aisle
            case .aisle:
                sectionSplitType = .none
            }
            self.observe(filterText: self.searchTextRaw)
        }
        
        private var searchTextRaw: String = ""
        var searchText: Binding<String> {
            Binding(
                get: { self.searchTextRaw },
                set: {
                    self.searchTextRaw = $0
                    self.observe(filterText: self.searchTextRaw)
                }
            )
        }
        
        func addRecipe() {
            try? appDatabase.dbWriter.write{ db in
                let recipeEntry = RecipeEntryInsert(recipeSectionId: 4, recipeId: 4, itemId: 44, amount: Amount(1.0, type: .count))
                try recipeEntry.insert(db)
            }
        }
        
        func addItem(itemName: String) {
            try? appDatabase.addItem(itemName: itemName)
        }
        
        func deleteItem(itemId: Int) {
            try? appDatabase.deleteItem(itemId: itemId)
        }
        
        func renameItem(itemId: Int, newName: String) {
            try? appDatabase.renameItem(itemId: itemId, newName: newName)
        }
        
        // MARK: - Alerts
        private(set) var alertType: AlertType = AlertType.none
        private(set) var alertId: Int = -1
        
        private(set) var alertTitle: String = ""
        private(set) var alertMessage: String = ""
        private(set) var alertConfirmText: String = ""
        private(set) var alertDismissText: String = "Cancel"
        private(set) var alertPlaceholder: String = "Aisle Name"
        
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
            alertTitle = "Add Item"
            alertMessage = "Please enter the name for the new Item"
            alertConfirmText = "Add"
        }
        
        func queueRenameItemAlert(itemId: Int, itemName: String) {
            alertId = itemId
            alertTextEntry = itemName
            alertType = .rename
            alertTitle = "Rename Item"
            alertMessage = "Please enter the new name for the Item"
            alertConfirmText = "Rename"
        }
        
        func queueDeleteItemAlert(itemId: Int, itemsInUse: String) {
            let itemsInUseArr: [String] = itemsInUse.components(separatedBy: ",")
            let itemsInUseString: String = itemsInUseArr.count > 8
            ? itemsInUseArr.prefix(8).joined(separator: "\n") + "\n..."
            : itemsInUseArr.joined(separator: "\n")
            
            alertId = itemId
            alertTextEntry = ""
            alertType = .delete
            alertTitle = "Delete Item?"
            alertMessage = "This Item is used by the following recipes:\n\(itemsInUseString)"
            alertConfirmText = "Delete"
        }
        
        func dismissAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .none
        }
    }
}
