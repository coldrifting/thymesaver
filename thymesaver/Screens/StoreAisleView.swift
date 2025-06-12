import SwiftUI
import SwiftData

struct StoreAisleView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var stores: [Store]
    @Query private var aisles: [Aisle]
    
    @State private var presentAlert: Bool = false
    @State private var aisleRename: Bool = false
    @State private var aisleRenameId: UUID?
    @State private var aisleRenameName: String = ""
    
    private var storeId: UUID
    private var storeName: String
    
    init(storeId: UUID, storeName: String) {
        self.storeId = storeId
        self.storeName = storeName
        
        _aisles = Query(filter: #Predicate<Aisle> { storeId == $0.store.uuid }, sort: \Aisle.order)
    }
    
    var body: some View {
        List {
            Section("Aisles") {
                ForEach(aisles) { aisle in
                    HStack {
                        Text(aisle.name)
                        Spacer()
                        Text("\(aisle.order + 1)").foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            aisleRenameId = aisle.uuid
                            aisleRenameName = aisle.name
                            aisleRename = true
                            presentAlert = true
                        } label: {
                            Text("Rename")
                        }
                        .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
                    }
                }
                .onMove(perform: { indices, newOffset in
                    var s = aisles
                    s.move(fromOffsets: indices, toOffset: newOffset)
                    for (index, item) in s.enumerated() {
                        item.order = index
                    }
                })
                .onDelete { indexSet in
                    deleteAisle(index: indexSet)
                }
                .deleteDisabled(aisles.count <= 1)
            }
        }
        .toolbar {
            ToolbarItem {
                EditButton()
            }
            ToolbarItem {
                Button {
                    aisleRenameId = nil
                    aisleRenameName = ""
                    aisleRename = false
                    presentAlert = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .alert(aisleRename ? "Rename Store" : "New Store", isPresented: $presentAlert, actions: {
            TextField("Store Name", text: $aisleRenameName)
            
            Button(aisleRename ? "Rename" : "Add", action: {
                if (aisleRename) {
                    renameAisle(aisleId: aisleRenameId!, newName: aisleRenameName.trim())
                }
                else {
                    addAisle(aisleName: aisleRenameName.trim(), storeId: storeId)
                }
            })
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text(aisleRename ? "Please enter the new name for this Aisle." : "Please enter a name for the new Aisle.")
        })
        .navigationTitle(Text(storeName))
    }
    
    private func addAisle(aisleName: String, storeId: UUID) {
        withAnimation {
            if let firstAisle = aisles.last {
                let store = firstAisle.store
                let sortIndex = firstAisle.order + 1
                
                let aisle = Aisle(name: aisleName, store: store, order: sortIndex)
                modelContext.insert(aisle)
            }
            else if let store = stores.first(where: { $0.uuid == storeId}) {
                let aisle = Aisle(name: aisleName, store: store, order: 0)
                modelContext.insert(aisle)
            }
        }
    }
    
    
    private func renameAisle(aisleId: UUID, newName: String) {
        withAnimation {
            for aisle in aisles where aisle.uuid == aisleId {
                aisle.name = newName
            }
        }
    }
    
    private func deleteAisle(index: IndexSet) {
        withAnimation {
            var decrement: Bool = false
            for (targetIndex) in index.sorted(by: <) {
                for (itemIndex, item) in aisles.enumerated() {
                    if (targetIndex == itemIndex) {
                        modelContext.delete(item)
                        decrement = true
                    }
                    else if (decrement) {
                        item.order -= 1
                    }
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        StoreAisleView(storeId: UUID(number: 0), storeName: "Macey's (1700 S)")
            .modelContainer(previewContainer)
    }
}
