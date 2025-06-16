import SwiftUI
import Observation
import Combine

struct ItemDetailsView: View {
    @State private var viewModel: ViewModel
    
    @State private var itemPreps: [ItemPrepExpanded] = []
    private var itemId: Int
    private var itemName: String
    
    init(_ appDatabase: AppDatabase, itemId: Int, itemName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
        self.itemId = itemId
        self.itemName = itemName
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
                
                FilterSelectionPicker("Aisle", selection: viewModel.currentAisleId, options: viewModel.aisles)
                
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
                                action: { viewModel.queueRenameItemAlert(itemId: itemPrep.itemPrepId, itemName: itemPrep.prepName) },
                                label: { Text("Rename") }
                            )
                            .tint(.blue)
                        }
                        .if(itemPrep.usedIn.count > 0) { v in
                            v
                            .swipeActions(edge: .trailing) {
                                Button(
                                    action: {
                                        viewModel.queueDeleteItemAlert(itemId: itemPrep.itemPrepId, itemsInUse: itemPrep.usedIn)
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
        .navigationTitle(Text(itemName))
        .toolbar {
            ToolbarItem {
                Button (
                    action: { viewModel.queueAddItemAlert() },
                    label: { Label("Add Item Preperation", systemImage: "plus") }
                )
            }
        }
        .onAppear() {
            viewModel.observe(itemId: self.itemId)
        }
        .onReceive(Just(viewModel.itemPreps)) { itemPreps in
            withAnimation {
                self.itemPreps = viewModel.itemPreps
            }
        }
        .customAlert(
            title: viewModel.alertTitle,
            message: viewModel.alertMessage,
            placeholder: viewModel.alertPlaceholder,
            onConfirm: { stringValue in
                switch viewModel.alertType {
                case .add:
                    viewModel.addItem(itemName: stringValue)
                case .rename:
                    viewModel.renameItem(itemId: viewModel.alertId, newName: stringValue)
                case .delete:
                    viewModel.deleteItem(itemId: viewModel.alertId)
                case .none:
                    break
                }
            },
            onDismiss: viewModel.dismissAlert,
            alertType: viewModel.alertType,
            $text: viewModel.alertTextBinding
        )
    }
}

#Preview {
    NavigationStack {
        ItemDetailsView(.shared, itemId: 207, itemName: "Cucumbers")
    }
}
