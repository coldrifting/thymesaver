import SwiftUI
import SwiftData

struct StoreView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var stores: [Store]
    @Query(filter: #Predicate<Store> { $0.selected }) private var selectedStoreQuery: [Store]
    
    @State private var presentAlert: Bool = false
    @State private var storeRename: Bool = false
    @State private var storeRenameId: UUID?
    @State private var storeRenameName: String = ""
    
    var body: some View {
        let selectedStoreNullable = selectedStoreQuery.first
        
        NavigationSplitView {
            List {
                if let selectedStore = selectedStoreNullable {
                    Section("Selected Store") {
                        NavigationLink() {
                            StoreAisleView(storeId: selectedStore.uuid, storeName: selectedStore.name)
                        } label: {
                            Text(selectedStore.name)
                        }
                    }
                }
                
                Section("All Stores") {
                    ForEach(stores.sorted()) { storeItem in
                        let selected : Bool = storeItem.uuid == selectedStoreNullable?.uuid
                        
                        Button(action: {
                            selectStore(storeId: storeItem.uuid)
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
                                Text(storeItem.name)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                storeRenameId = storeItem.uuid
                                storeRenameName = storeItem.name
                                storeRename = true
                                presentAlert = true
                            } label: {
                                Text("Rename")
                            }
                            .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
                        }
                        .if(stores.count > 1 && !selected) { view in
                            view
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteStore(storeId: storeItem.uuid)
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
                        populate(context: modelContext)
                    }.foregroundStyle(Color.red)
                }
                ToolbarItem {
                    Button {
                        storeRenameId = nil
                        storeRenameName = ""
                        storeRename = false
                        presentAlert = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .alert(storeRename ? "Rename Store" : "New Store", isPresented: $presentAlert, actions: {
                TextField("Store Name", text: $storeRenameName)
                
                Button(storeRename ? "Rename" : "Create", action: {
                    if (storeRename) {
                        renameStore(storeId: storeRenameId!, newName: storeRenameName.trim())
                    }
                    else {
                        addStore(storeName: storeRenameName.trim())
                    }
                })
                Button("Cancel", role: .cancel, action: {})
            }, message: {
                Text(storeRename ? "Please enter the new name for this store." : "Please enter a name for the new store.")
            })
            .navigationTitle(Text("Stores"))
        } detail: {
            Text("Select a store")
        }
    }
    
    private func selectStore(storeId: UUID) {
        withAnimation {
            for store in stores {
                store.selected = store.uuid == storeId
            }
        }
    }
    
    private func getStoreName(storeId: UUID) -> String {
        for store in stores where store.uuid == storeId {
            return store.name
        }
        return "Invalid Store"
    }
    
    private func addStore(storeName: String) {
        withAnimation {
            let newStore = Store(name: storeName)
            modelContext.insert(newStore)
        }
    }
    
    
    private func renameStore(storeId: UUID, newName: String) {
        withAnimation {
            for store in stores where store.uuid == storeId {
                store.name = newName
                break
            }
        }
    }
    
    private func deleteStore(storeId: UUID) {
        withAnimation {
            for store in stores where store.uuid == storeId {
                modelContext.delete(store)
            }
        }
    }
}

#Preview {
    StoreView()
        .modelContainer(previewContainer)
}
