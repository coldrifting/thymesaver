import SwiftUI
import Observation
import Combine

struct StoreView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    @State private var stores: [Store] = []
    @State private var selectedStoreId: Int = -1
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack {
            List {
                selectedStoreLink()
                allStores()
            }
            .navigationTitle(Text("Stores"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(
                        action: { viewModel.reset() },
                        label: { Text("Reset Data").foregroundStyle(Color.red) }
                    )
                }
                ToolbarItem {
                    Button(
                        action: { viewModel.alert.queueAdd() },
                        label: { Label("Add Store", systemImage: "plus") }
                    )
                }
            }
            .onAppear { viewModel.observe() }
            .onReceive(Just(viewModel.stores)) { stores in
                withAnimation {
                    self.stores = stores
                }
            }
            .onReceive(Just(viewModel.selectedStoreId)) { selectedStoreId in
                withAnimation {
                    self.selectedStoreId = selectedStoreId
                }
            }
            .alertCustom(viewModel.alert)
        }
    }
    
    func selectedStoreLink() -> some View {
        Section("Selected Store") {
            if (selectedStoreId == -1) {
                Text("None Selected")
            }
            else {
                let selectedStore: Store = stores.first(where: { $0.storeId == selectedStoreId })!
                NavigationLink(
                    destination: { AisleView(appDatabase, storeId: selectedStoreId, storeName: selectedStore.storeName) },
                    label: { Text(selectedStore.storeName) }
                )
            }
        }
    }
    
    func storeItem(name: String, selected: Bool) -> some View {
        HStack {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
                .accessibilityLabel(selected ? "Selected" : "Unselected")
                .padding([.trailing], 4)
            Text(name)
        }
    }
    
    func allStores() -> some View {
        Section("All Stores") {
            ForEach(self.stores) { store in
                let storeId: Int = store.storeId
                let storeName: String = store.storeName
                let selected: Bool = storeId == self.selectedStoreId
                
                Button(
                    action: { viewModel.selectStore(storeId: store.storeId) },
                    label: { storeItem(name: store.storeName, selected: selected) }
                )
                .foregroundStyle(.primary)
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.alert.queueRename(id: storeId, name: storeName)
                    } label: {
                        Text("Rename")
                    }
                    .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
                }
                .deleteDisabled(selected)
            }
            .onDelete { offsets in
                offsets.forEach { index in
                    viewModel.deleteStore(storeId: stores[index].storeId)
                }
            }
        }
    }
}

#Preview {
    StoreView(.shared)
}
