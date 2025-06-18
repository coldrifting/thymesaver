import SwiftUI
import GRDB

extension ItemDetailsView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase, itemId: Int, itemName: String) {
            self.appDatabase = appDatabase
            self.itemId = itemId
            self.itemName = itemName
            
            self.alert = AlertViewModel.init(
                itemName: "Item Preperation",
                addAction: { newName in appDatabase.addItemPrep(itemId: itemId, prepName: newName) },
                renameAction: appDatabase.renameItemPrep,
                deleteAction: appDatabase.deleteItemPrep
            )
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                try (
                    stores: Store.fetchAll(db),
                    aisles: Aisle.getAisles(db),
                    item: Item.fetchOne(db, key: self.itemId),
                    itemLocs: ItemAisle.getItemAisles(db, itemId: self.itemId),
                    itemPreps: ItemPrepExpanded.getItemPreps(db, itemId: self.itemId)
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
        
        let itemId: Int
        let itemName: String
        
        private(set) var stores: [Store] = []
        private(set) var aisles: [(id: Int, name: String)] = []
        
        private var item: Item? = nil
        private var itemLocs: [ItemAisle] = []
        private(set) var itemPreps: [ItemPrepExpanded] = []
        
        private(set) var showBay: Bool = false
        
        var itemTemp: Binding<ItemTemp> {
            Binding(
                get: { self.item?.itemTemp ?? .ambient },
                set: { self.appDatabase.updateItemTemp(itemId: self.item?.id ?? -1, itemTemp: $0) }
            )
        }
        
        var itemDefaultUnits: Binding<UnitType> {
            Binding(
                get: { self.item?.defaultUnits ?? .count },
                set: { self.appDatabase.updateItemDefaultUnits(itemId: self.item?.id ?? -1, defaultUnits: $0) }
            )
        }
        
        var currentStoreId: Binding<Int> {
            Binding(
                get: { (try? self.appDatabase.getSelectedStoreId()) ?? -1 },
                set: { storeId in self.appDatabase.selectStore(storeId: storeId) }
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
            self.appDatabase.updateItemAisle(itemId: self.item?.id ?? -1, storeId: selectedStoreId, aisleId: aisleId)
        }
        
        func updateAisleBay(itemId: Int, bay: BayType) {
            let selectedStoreId = (try? self.appDatabase.getSelectedStoreId()) ?? -1
            self.appDatabase.updateItemAisleBay(itemId: itemId, storeId: selectedStoreId, newBay: bay)
        }
        
        func addItem(itemName: String) {
            self.appDatabase.addItemPrep(itemId: self.item?.id ?? -1, prepName: itemName)
        }
        
        func deleteItem(itemId: Int) {
            self.appDatabase.deleteItemPrep(itemPrepId: itemId)
        }
        
        func renameItem(itemId: Int, newName: String) {
            self.appDatabase.renameItemPrep(itemPrepId: itemId, newName: newName)
        }
        
        var alert: AlertViewModel
    }
}
