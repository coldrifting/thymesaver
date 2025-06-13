import SwiftUI

struct StoreView: View {
    @State private var viewModel: ViewModel
    
    init(appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase: appDatabase))
    }
    
    var body: some View {
        NavigationSplitView {
            List {
                if let selectedStore = viewModel.selectedStore {
                    Section("Selected Store") {
                        NavigationLink() {
                            EmptyView() // TODO - StoreAisleView(storeId: selectedStore.id, storeName: selectedStore.name)
                        } label: {
                            Text(selectedStore.storeName)
                        }
                    }
                }
                
                Section("All Stores") {
                    ForEach(viewModel.stores) { storeItem in
                        let selected : Bool = storeItem.storeId == viewModel.selectedStore?.storeId
                        
                        Button(action: {
                            withAnimation {
                                viewModel.selectStore(storeId: storeItem.storeId)
                            }
                        }) {
                            HStack {
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .renderingMode(.original)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.gray)
                                    .accessibilityLabel(selected ? "Selected" : "Unselected")
                                    .padding([.trailing], 4)
                                Text(storeItem.storeName)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button() {
                                viewModel.queueRenameItemAlert(itemId: storeItem.storeId, itemName: storeItem.storeName)
                            } label: {
                                Text("Rename")
                            }
                            .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
                        }
                        .if(viewModel.stores.count > 1 && !selected) { view in
                            view
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        viewModel.deleteStore(storeId: storeItem.storeId)
                                    } label: {
                                        Text("Delete")
                                    }
                                }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset Data") {
                        viewModel.reset()
                    }.foregroundStyle(Color.red)
                }
                ToolbarItem {
                    Button {
                        viewModel.queueAddItemAlert()
                    } label: {
                        Label("Add Store", systemImage: "plus")
                    }
                }
            }
            .customAlert(
                title: viewModel.alertType == AlertType.rename
                    ? "Rename Store"
                    : "New Store",
                message: viewModel.alertType == AlertType.rename
                    ? "Please enter the new name for this store."
                    : "Please enter a name for the new store.",
                placeholder: "Store Name",
                onConfirm: viewModel.alertType == AlertType.rename
                    ? { viewModel.renameStore(storeId: viewModel.alertId, newName: $0)}
                    : { viewModel.addStore(storeName: $0)},
                onDismiss: viewModel.dismissAlert,
                alertType: viewModel.alertType,
                $text: viewModel.alertTextBinding
            )
            .navigationTitle(Text("Stores"))
        } detail: {
            Text("Select a store")
        }.onAppear {
            viewModel.observe()
        }
    }
}

#Preview {
    StoreView(appDatabase: .shared)
}
