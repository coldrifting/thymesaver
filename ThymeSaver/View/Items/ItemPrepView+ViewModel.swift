import SwiftUI
import GRDB

extension ItemPrepView {
    @Observable @MainActor
    class ViewModel {
        private(set) var itemId: Int
        private(set) var itemName: String
        
        var itemPreps: Set<Prep> = []
        private(set) var allPreps: [Prep] = []
        private(set) var prepRecipeInfo: [Int:[String]] = [:]
        
        private(set) var alert: AlertViewModel
        
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase, itemId: Int, itemName: String) {
            self.appDatabase = appDatabase
            self.itemId = itemId
            self.itemName = itemName
            
            self.alert = AlertViewModel.init(
                itemName: "Item Preperation",
                addAction: { newName in appDatabase.addPrep(prepName: newName) },
                renameAction: appDatabase.renamePrep,
                deleteAction: { prepId in appDatabase.deleteItemPrep(itemId: itemId, prepId: prepId) }
            )
        }
        
        func observe() {
            let itemId = self.itemId
            let observation = ValueObservation.tracking { db in
                try (
                    itemPreps: Prep.get(itemId: itemId).fetchAll(db),
                    allPreps: Prep.order{ $0.prepName.lowercased }.fetchAll(db).filter({$0.prepId != 0}),
                    prepRecipeInfo: PrepRecipeInfo.getRecipesUsingPrep().fetchAll(db)
                )
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { (itemPreps, allPreps, prepRecipeInfo) in
                self.itemPreps = Set<Prep>(itemPreps)
                self.allPreps = allPreps
                self.prepRecipeInfo = prepRecipeInfo.reduce(into: [:], { $0[$1.id] = $1.recipes.split(separator: "|", omittingEmptySubsequences: true).map{$0.description} })
            }
        }
        
        func selectPrep(prep: Prep) {
            self.appDatabase.addItemPrep(itemId: self.itemId, prepId: prep.prepId)
        }
        
        func unselectPrep(prep: Prep) {
            self.appDatabase.deleteItemPrep(itemId: self.itemId, prepId: prep.prepId)
        }
        
        func deletePrep(prepId: Int) {
            self.appDatabase.deletePrep(prepId: prepId)
        }
        
        func deleteItemPrep(itemId: Int, prepId: Int) {
            self.appDatabase.deleteItemPrep(itemId: itemId, prepId: prepId)
        }
    }
}
