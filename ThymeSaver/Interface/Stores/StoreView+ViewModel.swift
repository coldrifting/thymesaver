import SwiftUI
import GRDB

extension StoreView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                try Store.fetchAll(db)
            }
            
            // Start observing the database.
            // Previous observation, if any, is cancelled.
            cancellable = observation.start(in: appDatabase.reader) { error in
                // Handle error
            } onChange: { [unowned self] stores in
                self.stores = stores
                selectedStore = stores.first(where: { $0.id == selectedStoreId })
                if (selectedStore == nil && !stores.isEmpty) {
                    selectedStoreId = stores.first?.id
                    selectedStore = stores.first
                }
            }
        }
        
        private var selectedStoreId: Int? = nil
        
        private(set) var stores: [Store] = []
        private(set) var selectedStore: Store? = nil
        
        private(set) var alertType: AlertType = AlertType.none
        private(set) var alertId: Int = -1
        
        private(set) var alertTextEntry: String = ""
        
        var alertTextBinding: Binding<String> {
            Binding(
                get: { self.alertTextEntry },
                set: { self.alertTextEntry = $0 }
            )
        }
        
        func selectStore(storeId: Int) {
            for store in stores {
                if (store.id == storeId) {
                    selectedStoreId = storeId
                    self.selectedStore = store
                    break
                }
            }
        }
        
        func addStore(storeName: String) {
            try? appDatabase.addStore(storeName: storeName)
        }
        
        func deleteStore(storeId: Int) {
            try? appDatabase.deleteStore(storeId: storeId)
        }
        
        func renameStore(storeId: Int, newName: String) {
            try? appDatabase.renameStore(storeId: storeId, newName: newName)
        }
        
        func reset() {
            try? appDatabase.resetStores()
        }
        
        func queueAddItemAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .add
        }
        
        func queueRenameItemAlert(itemId: Int, itemName: String) {
            alertId = itemId
            alertTextEntry = itemName
            alertType = .rename
        }
        
        func dismissAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .none
        }
    }
}
