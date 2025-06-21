import SwiftUI
import Observation
import Combine

struct ItemDetailsView: View {
    @Environment(\.appDatabase) var appDatabase
    
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
                
                NavigationLink(
                    destination: {
                        ItemPrepView(
                            appDatabase,
                            itemId: viewModel.itemId,
                            itemName: viewModel.itemName
                        )
                    },
                    label: {
                        HStack {
                            Text("Preps")
                            Spacer()
                            Text(viewModel.prepsString).foregroundStyle(.secondary)
                        }
                    }
                )
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
        }
        .navigationTitle(viewModel.itemName).navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            viewModel.observe()
        }
    }
}

#Preview {
    NavigationStack {
        ItemDetailsView(.shared, itemId: 207, itemName: "Cucumbers")
    }
}
