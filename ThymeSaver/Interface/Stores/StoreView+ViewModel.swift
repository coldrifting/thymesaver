import SwiftUI
import GRDB

extension StoreView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        @ObservationIgnored private var cancellable2: AnyDatabaseCancellable?
        
        init(appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                try Store.fetchAll(db)
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { [unowned self] stores in
                self.stores = stores
            }
            
            let observation2 = ValueObservation.tracking { db in
                try Config.find(db)
            }
            
            // Start observing the database.
            // Previous observation, if any, is cancelled.
            cancellable2 = observation2.start(in: appDatabase.reader) { _ in
            } onChange: { [unowned self] config in
                self.selectedStoreId = config.selectedStore
            }
        }
        
        private(set) var selectedStoreId: Int = -1
        
        private(set) var stores: [Store] = []
        
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
