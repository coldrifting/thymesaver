import SwiftUI
import Observation
import Combine

struct ItemDetailsView: View {
    @State private var viewModel: ViewModel
    
    private var itemId: Int
    private var itemName: String
    
    init(_ appDatabase: AppDatabase, itemId: Int, itemName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
        self.itemId = itemId
        self.itemName = itemName
    }
    
    @State private var preps: [String] = [
        "Sliced",
        "Diced",
        "Chopped"
    ]
    
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
                if (viewModel.itemPreps.isEmpty) {
                    Text("Default").foregroundStyle(.secondary)
                }
                else {
                    ForEach(viewModel.itemPreps, id: \.id) { itemPrep in
                        Text(itemPrep.prepName)
                        .swipeActions(edge: .leading) {
                            Button(
                                action: { viewModel.queueRenameItemPrepAlert(itemPrepId: itemPrep.itemPrepId, itemPrepName: itemPrep.prepName) },
                                label: { Text("Rename") }
                            )
                            .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
                        }
                    }
                    .onDelete { offsets in
                        offsets.forEach { index in
                            viewModel.deleteItemPrep(itemPrepId: viewModel.itemPreps[index].itemPrepId)
                        }
                    }
                }
            }
        }
        .navigationTitle(Text(itemName))
        .toolbar {
            ToolbarItem {
                Button (
                    action: { viewModel.queueAddItemPrepAlert() },
                    label: { Label("Add Item Preperation", systemImage: "plus") }
                )
            }
        }
        .onAppear() {
            viewModel.observe(itemId: self.itemId)
        }
        .customAlert(
            title: viewModel.alertTitle,
            message: viewModel.alertMessage,
            placeholder: viewModel.alertPlaceholder,
            onConfirm: viewModel.alertType == AlertType.rename
            ? { viewModel.renameItemPrep(itemPrepId: viewModel.alertId, newName: $0)}
            : { viewModel.addItemPrep(itemPrepName: $0)},
            onDismiss: viewModel.dismissAlert,
            alertType: viewModel.alertType,
            $text: viewModel.alertTextBinding
        )
    }
}

#Preview {
    NavigationStack {
        ItemDetailsView(.shared, itemId: 184, itemName: "Pepper Jack Cheese")
    }
}
