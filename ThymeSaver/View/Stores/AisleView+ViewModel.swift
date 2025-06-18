import SwiftUI
import GRDB

extension AisleView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase, storeId: Int) {
            self.appDatabase = appDatabase
            self.storeId = storeId
            
            self.alert = AlertViewModel.init(
                itemName: "Aisle",
                addAction: { aisleName in appDatabase.addAisle(aisleName: aisleName, storeId: storeId) } ,
                renameAction: appDatabase.renameAisle
            )
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                return try Aisle.getAisles(db)
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { aisles in
                self.aisles = aisles
            }
        }
        
        private let storeId: Int
        private(set) var aisles: [Aisle] = []
        
        func moveAisle(aisleId: Int, newIndex: Int) {
            appDatabase.moveAisle(aisleId: aisleId, newIndex: newIndex)
        }
        
        func deleteAisle(aisleId: Int, storeId: Int) {
            appDatabase.deleteAisle(aisleId: aisleId, storeId: storeId)
        }
        
        var alert: AlertViewModel
    }
}
