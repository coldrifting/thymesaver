import SwiftUI
import GRDB

extension ItemsView {
    enum SectionSplitType: CaseIterable {
        case none
        case temp
        case aisle
    }
    
    @Observable @MainActor
    class ViewModel {
        private let appDatabase: AppDatabase
        @ObservationIgnored private var cancellable: AnyDatabaseCancellable?
        
        init(_ appDatabase: AppDatabase) {
            self.appDatabase = appDatabase
            
            self.alert = AlertViewModel.init(
                itemName: "Item",
                addAction: appDatabase.addItem,
                renameAction: appDatabase.renameItem,
                deleteAction: appDatabase.deleteItem
            )
        }
        
        func observe(filterText: String) {
            let observation = ValueObservation.tracking { db in
                ItemExpanded.getItemsFiltered(db, itemNameFilter: filterText)
            }
            
            cancellable = observation.start(in: appDatabase.reader) { _ in
            } onChange: { items in
                self.itemsWithAisleInfo = self.splitItemsBySection(items: items)
            }
        }
        
        private(set) var itemsWithAisleInfo: [(section: String, items: [ItemExpanded])] = []
        private(set) var sectionSplitType: SectionSplitType = .none
        
        func splitItemsBySection(items: [ItemExpanded]) -> [(section: String, items: [ItemExpanded])] {
            switch self.sectionSplitType {
            case .none:
                return [(section: "All Items by Name", items: items)]
            case .temp:
                return Dictionary(grouping: items, by: { $0.itemTemp} )
                    .sorted(by: { $0.key < $1.key })
                    .map{ ("\($0.key)", $0.value) }
            case .aisle:
                return Dictionary(grouping: items, by: { $0.aisleId} )
                    .sorted(by: { $0.value.first?.aisleOrder ?? Int.max < $1.value.first?.aisleOrder ?? Int.max })
                    .map{ ("\($0.value.first?.aisleName ?? "No Aisle Assigned")", $0.value) }
            }
        }
        
        func cycleSectionSplitType() {
            switch sectionSplitType {
            case .none:
                sectionSplitType = .temp
            case .temp:
                sectionSplitType = .aisle
            case .aisle:
                sectionSplitType = .none
            }
            self.observe(filterText: self.searchTextRaw)
        }
        
        private var searchTextRaw: String = ""
        var searchText: Binding<String> {
            Binding(
                get: { self.searchTextRaw },
                set: {
                    self.searchTextRaw = $0
                    self.observe(filterText: self.searchTextRaw)
                }
            )
        }
        
        func addItem(itemName: String) {
            appDatabase.addItem(itemName: itemName)
        }
        
        func deleteItem(itemId: Int) {
            appDatabase.deleteItem(itemId: itemId)
        }
        
        func renameItem(itemId: Int, newName: String) {
            appDatabase.renameItem(itemId: itemId, newName: newName)
        }
        
        var alert: AlertViewModel
    }
}
