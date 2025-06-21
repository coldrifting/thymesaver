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
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                try (
                    stores: Store.fetchAll(db),
                    aisles: Aisle.getAisles(db),
                    item: Item.fetchOne(db, key: self.itemId),
                    itemLocs: ItemAisle.getItemAisles(db, itemId: self.itemId),
                    preps: Prep.get(itemId: self.itemId).fetchAll(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (stores, aisles, item, itemLocs, preps) in
                self.stores = stores
                self.aisles = aisles
                self.item = item
                self.itemLocs = itemLocs
                self.preps = preps
                
                let selectedStoreId = (try? self.appDatabase.getSelectedStoreId()) ?? -1
                let hasItemAisle: Bool = self.itemLocs.first{ $0.storeId == selectedStoreId } != nil
                
                self.showBay = hasItemAisle
            }
        }
        
        let itemId: Int
        let itemName: String
        
        private(set) var stores: [Store] = []
        private(set) var aisles: [Aisle] = []
        
        private var item: Item? = nil
        private var itemLocs: [ItemAisle] = []
        
        private var preps: [Prep] = []
        var prepsString: String {
            if (preps.isEmpty) {
                return "(None)"
            }
            return preps.reduce("", { $0 + ", " + $1.prepName }).deletingPrefix(", ").chop(24)
        }
        
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
        
        var currentAisle: Binding<Aisle?> {
            Binding(
                get: {
                    if let aisleId: Int? = self.itemLocs.first(where: { $0.storeId == (try? self.appDatabase.getSelectedStoreId()) ?? -1 })?.aisleId {
                        return self.aisles.first(where: {$0.aisleId == aisleId })
                    }
                    return nil
                },
                set: { aisle in
                    if let aisleNotNull = aisle {
                        self.addOrUpdateItemAisle(aisleId: aisleNotNull.id)
                    }
                }
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
    }
}
