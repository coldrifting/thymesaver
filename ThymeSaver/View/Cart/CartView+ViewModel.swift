import SwiftUI
import GRDB

extension CartView {
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
        }
        
        func observe() {
            let observation = ValueObservation.tracking { db in
                (
                    CartAisle.fetchAll(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { cartAisles in
                self.cartAisles = cartAisles
            }
        }
        
        var cartAisles: [CartAisle] = []
        
        func toggleCartEntryChecked(entryId: Int) {
            self.appDatabase.toggleCartEntryChecked(entryId: entryId)
        }
    }
}
