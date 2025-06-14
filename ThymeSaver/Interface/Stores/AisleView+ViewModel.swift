import SwiftUI
import GRDB

extension AisleView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe(storeId: Int) {
            let observation = ValueObservation.tracking { db in
                return try Aisle.getAisles(db)
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { aisles in
                self.aisles = aisles
            }
        }
        
        private(set) var aisles: [Aisle] = []
        
        func addAisle(aisleName: String, storeId: Int) {
            try? appDatabase.addAisle(aisleName: aisleName, storeId: storeId)
        }
        
        func deleteAisle(aisleId: Int, storeId: Int) {
            try? appDatabase.deleteAisle(aisleId: aisleId, storeId: storeId)
        }
        
        func renameAisle(aisleId: Int, newName: String) {
            try? appDatabase.renameAisle(aisleId: aisleId, newName: newName)
        }
        
        func moveAisle(aisleId: Int, newIndex: Int) {
            try? appDatabase.moveAisle(aisleId: aisleId, newIndex: newIndex)
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
            alertTitle = "Add Aisle"
            alertMessage = "Please enter the name for the new Aisle"
            alertConfirmText = "Add"
        }
        
        func queueRenameItemAlert(itemId: Int, itemName: String) {
            alertId = itemId
            alertTextEntry = itemName
            alertType = .rename
            alertTitle = "Rename Aisle"
            alertMessage = "Please enter the new name for the Aisle"
            alertConfirmText = "Rename"
        }
        
        func dismissAlert() {
            alertId = -1
            alertTextEntry = ""
            alertType = .none
        }
    }
}
