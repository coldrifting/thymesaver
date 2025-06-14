import SwiftUI
import GRDB

extension StoreView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                try (
                    stores: Store.fetchAll(db),
                    config: Config.find(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (stores, config) in
                self.stores = stores
                self.selectedStoreId = config.selectedStore
            }
        }
        
        private(set) var selectedStoreId: Int = -1
        private(set) var stores: [Store] = []
        
        func selectStore(storeId: Int) {
            try? appDatabase.selectStore(storeId: storeId)
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
            try? appDatabase.reset()
        }
        
        // MARK: - Alerts
        private(set) var alertType: AlertType = AlertType.none
        private(set) var alertId: Int = -1
        
        private(set) var alertTitle: String = ""
        private(set) var alertMessage: String = ""
        private(set) var alertConfirmText: String = ""
        private(set) var alertDismissText: String = "Cancel"
        private(set) var alertPlaceholder: String = "Store Name"
        
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
            alertTitle = "Add Store"
            alertMessage = "Please enter the name for the new Store"
            alertConfirmText = "Add"
        }
        
        func queueRenameItemAlert(itemId: Int, itemName: String) {
            alertId = itemId
            alertTextEntry = itemName
            alertType = .rename
            alertTitle = "Rename Store"
            alertMessage = "Please enter the new name for the store"
            alertConfirmText = "Rename"
        }
        
        func dismissAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .none
        }
    }
}
