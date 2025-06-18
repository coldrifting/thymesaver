import SwiftUI
import GRDB

extension StoreView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
            
            self.alert = AlertViewModel.init(
                itemName: "Store",
                addAction: appDatabase.addStore,
                renameAction: appDatabase.renameStore
            )
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
            appDatabase.selectStore(storeId: storeId)
        }
        
        func deleteStore(storeId: Int) {
            appDatabase.deleteStore(storeId: storeId)
        }
        
        func reset() {
            try? appDatabase.reset()
        }
        
        var alert: AlertViewModel
    }
}
