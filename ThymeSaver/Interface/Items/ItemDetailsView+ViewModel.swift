import SwiftUI
import GRDB

extension ItemDetailsView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe(itemId: Int) {
            let observation = ValueObservation.tracking { db in
                try (
                    stores: Store.fetchAll(db),
                    aisles: Aisle.getAisles(db),
                    item: Item.fetchOne(db, key: itemId),
                    itemLocs: ItemAisle.getItemAisles(db, itemId: itemId),
                    itemPreps: ItemPrepExpanded.getItemPreps(db, itemId: itemId)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (stores, aisles, item, itemLocs, itemPreps) in
                self.stores = stores
                self.aisles = aisles.map { (id: $0.id, name: $0.aisleName) }
                self.item = item
                self.itemLocs = itemLocs
                self.itemPreps = itemPreps
                
                let selectedStoreId = (try? self.appDatabase.getSelectedStoreId()) ?? -1
                let hasItemAisle: Bool = self.itemLocs.first{ $0.storeId == selectedStoreId } != nil
                
                self.showBay = hasItemAisle
            }
        }
        
        private(set) var stores: [Store] = []
        private(set) var aisles: [(id: Int, name: String)] = []
        
        private var item: Item? = nil
        private var itemLocs: [ItemAisle] = []
        private(set) var itemPreps: [ItemPrepExpanded] = []
        
        private(set) var showBay: Bool = false
        
        var itemTemp: Binding<ItemTemp> {
            Binding(
                get: { self.item?.itemTemp ?? .ambient },
                set: { try? self.appDatabase.updateItemTemp(itemId: self.item?.id ?? -1, itemTemp: $0) }
            )
        }
        
        var itemDefaultUnits: Binding<UnitType> {
            Binding(
                get: { self.item?.defaultUnits ?? .count },
                set: { try? self.appDatabase.updateItemDefaultUnits(itemId: self.item?.id ?? -1, defaultUnits: $0) }
            )
        }
        
        var currentStoreId: Binding<Int> {
            Binding(
                get: { (try? self.appDatabase.getSelectedStoreId()) ?? -1 },
                set: { storeId in try? self.appDatabase.selectStore(storeId: storeId) }
            )
        }
        
        var currentAisleId: Binding<Int> {
            Binding(
                get: { self.itemLocs.first{ $0.storeId == (try? self.appDatabase.getSelectedStoreId()) ?? -1 }?.aisleId ?? -1 },
                set: { aisleId in self.addOrUpdateItemAisle(aisleId: aisleId) }
            )
        }
        
        var bay: Binding<BayType> {
            Binding(
                get: { self.itemLocs.first{ $0.storeId == (try? self.appDatabase.getSelectedStoreId()) ?? -1 }?.bay ?? .middle },
                set: { bayType in self.updateAisleBay(itemId: self.item?.id ?? -1, bay: bayType) }
            )
        }
        
        func addOrUpdateItemAisle(aisleId: Int) {
            let selectedStoreId = (try? self.appDatabase.getSelectedStoreId()) ?? -1
            try? self.appDatabase.updateItemAisle(itemId: self.item?.id ?? -1, storeId: selectedStoreId, aisleId: aisleId)
        }
        
        func updateAisleBay(itemId: Int, bay: BayType) {
            let selectedStoreId = (try? self.appDatabase.getSelectedStoreId()) ?? -1
            try? self.appDatabase.updateItemAisleBay(itemId: itemId, storeId: selectedStoreId, newBay: bay)
        }
        
        func addItem(itemName: String) {
            try? self.appDatabase.addItemPrep(itemId: self.item?.id ?? -1, prepName: itemName)
        }
        
        func deleteItem(itemId: Int) {
            try? self.appDatabase.deleteItemPrep(itemPrepId: itemId)
        }
        
        func renameItem(itemId: Int, newName: String) {
            try? self.appDatabase.renameItemPrep(itemPrepId: itemId, newName: newName)
        }
        
        // MARK: - Alerts
        private(set) var alertType: AlertType = AlertType.none
        private(set) var alertId: Int = -1
        
        private(set) var alertTitle: String = ""
        private(set) var alertMessage: String = ""
        private(set) var alertConfirmText: String = ""
        private(set) var alertDismissText: String = "Cancel"
        private(set) var alertPlaceholder: String = "Item Preperation Name"
        
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
            alertMessage = "Please enter the name for the new Item Preperation"
            alertConfirmText = "Add"
        }
        
        func queueRenameItemAlert(itemId: Int, itemName: String) {
            alertId = itemId
            alertTextEntry = itemName
            alertType = .rename
            alertTitle = "Rename Item Preperation"
            alertMessage = "Please enter the new name for the Item Preperation"
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
            alertTitle = "Delete Item Prep?"
            alertMessage = "This Item Prep is used by the following recipes:\n\(itemsInUseString)"
            alertConfirmText = "Delete"
        }
        
        func dismissAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .none
        }
    }
}
