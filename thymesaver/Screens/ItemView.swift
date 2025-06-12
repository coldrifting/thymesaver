import SwiftUI
import SwiftData

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var items: [Item]
    
    @State private var presentAlert: Bool = false
    @State private var newItemName: String = ""
    
    @State private var itemSearchText: String = ""
    
    var body: some View {
        NavigationSplitView {
            VStack {
                List {
                    ForEach(items.sorted().filter({itemSearchText.trim().isEmpty || $0.name.lowercased().contains(itemSearchText.lowercased().trim())})) { item in
                        NavigationLink {
                            ItemDetailsView(itemId: item.uuid, itemTemp: item.temp, defaultUnits: item.defaultUnits, itemName: item.name)
                        } label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                
                                // TODO - Replace with selected store item location
                                Text("\(item.temp)".capitalized(with: .autoupdatingCurrent)).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                deleteItem(itemId: item.uuid)
                            } label: {
                                Text("Delete")
                            }
                        }
                    }
                }
            }
            .searchable(text: $itemSearchText)
            .alert("New Item", isPresented: $presentAlert, actions: {
                TextField("Item Name", text: $newItemName)
                
                Button("Add", action: {
                    addItem(itemName: newItemName.trim())
                })
                Button("Cancel", role: .cancel, action: {})
            }, message: {
                Text("Please enter a name for the new Item.")
            })
            .toolbar {
                ToolbarItem {
                    Button {
                        presentAlert = true
                        newItemName = ""
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(Text("Items"))
        } detail: {
            Text("Select an Item")
        }
    }
    
    private func addItem(itemName: String) {
        withAnimation {
            let newItem = Item(name: itemName)
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItem(itemId: UUID) {
        withAnimation {
            for item in items where item.uuid == itemId {
                modelContext.delete(item)
            }
        }
    }
}

#Preview {
    ItemView()
        .modelContainer(for: [Store.self], inMemory: true)
}
