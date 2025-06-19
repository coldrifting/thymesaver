import SwiftUI
import Observation
import Combine

struct ItemDetailsView: View {
    @State private var viewModel: ViewModel
    
    @State private var itemPreps: [ItemPrepExpanded] = []
    
    init(_ appDatabase: AppDatabase, itemId: Int, itemName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase, itemId: itemId, itemName: itemName))
    }
    
    var body: some View {
        List {
            Section("Details") {
                Picker("Temperature", selection: viewModel.itemTemp) {
                    ForEach(ItemTemp.allCases) { option in
                        Text(String(describing: option).capitalized).tag(option)
                    }
                }
                
                Picker("Default Units", selection: viewModel.itemDefaultUnits) {
                    ForEach(UnitType.allCases) { option in
                        Text(String(describing: option).capitalized).tag(option)
                    }
                }
            }
                
            Section("Location") {
                Picker("Store", selection: viewModel.currentStoreId) {
                    ForEach(viewModel.stores.map { x in x.id }, id: \.self) { storeIndex in
                        Text(viewModel.stores.first(where: { $0.id == storeIndex })?.storeName ?? "")
                    }
                }
                
                FilterSelectionPicker("Aisle", selection: viewModel.currentAisle, options: viewModel.aisles)
                
                if (viewModel.showBay) {
                    Picker("Bay", selection: viewModel.bay) {
                        ForEach(BayType.allCases) { option in
                            Text(String(describing: option).capitalized).tag(option)
                        }
                    }
                }
            }
            
            Section("Preperations") {
                if (itemPreps.isEmpty) {
                    Text("Default").foregroundStyle(.secondary)
                }
                else {
                    ForEach(itemPreps, id: \.id) { itemPrep in
                        Text(itemPrep.prepName)
                        .swipeActions(edge: .leading) {
                            Button(
                                action: { viewModel.alert.queueRename(id: itemPrep.itemPrepId, name: itemPrep.prepName) },
                                label: { Text("Rename") }
                            )
                            .tint(.blue)
                        }
                        .if(itemPrep.usedIn.count > 0) { v in
                            v
                            .swipeActions(edge: .trailing) {
                                Button(
                                    action: {
                                        viewModel.alert.queueDelete(id: itemPrep.itemPrepId, itemsInUse: itemPrep.usedIn)
                                    },
                                    label: { Text("Delete") }
                                )
                                .tint(.red)
                            }
                        }
                        .deleteDisabled(itemPrep.usedIn.count > 0)
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            viewModel.deleteItem(itemId: itemPreps[index].itemPrepId)
                        }
                    }
                }
            }
        }
        .navigationTitle(Text(viewModel.itemName)).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button (
                    action: { viewModel.alert.queueAdd() },
                    label: { Label("Add Item Preperation", systemImage: "plus") }
                )
            }
        }
        .onAppear() {
            viewModel.observe()
        }
        .onReceive(Just(viewModel.itemPreps)) { itemPreps in
            withAnimation {
                self.itemPreps = viewModel.itemPreps
            }
        }
        .alertCustom(viewModel.alert)
    }
}

#Preview {
    NavigationStack {
        ItemDetailsView(.shared, itemId: 207, itemName: "Cucumbers")
    }
}
