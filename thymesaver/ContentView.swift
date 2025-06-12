//
//  ContentView.swift
//  thymesaver
//
//  Created by Aiden Van Dyke on 6/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var stores: [Store]
    
    @State private var storeSelection: UUID?
    
    @State private var presentAlert = false
    @State private var storeRenameId: UUID?
    @State private var storeRenameName: String = ""
    @State private var storeRename: Bool = false
    
    var body: some View {
        TabView {
            Tab("Stores", systemImage: "location") {
                NavigationSplitView {
                    List {
                        if (storeSelection != nil) {
                            Section() {
                                NavigationLink() {
                                    EmptyView()
                                } label: {
                                    Text(getStoreName(storeId: storeSelection))
                                }
                            } header: {
                                Text("Selected Store")
                            }
                        }
                        
                        Section() {
                            ForEach(stores.sorted {$0.name < $1.name && $0.id < $1.id}) { storeItem in
                                Button(action: {
                                    storeSelection = storeItem.id
                                }) {
                                    HStack {
                                        Image(systemName: storeSelection == storeItem.id ? "checkmark.circle.fill" : "circle")
                                            .renderingMode(.original)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .foregroundColor(.gray)
                                            .accessibilityLabel(storeSelection == storeItem.id ? "Selected" : "Unselected")
                                            .padding([.trailing], 4)
                                        Text(storeItem.name)
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        storeRenameId = storeItem.id
                                        storeRenameName = storeItem.name
                                        presentAlert = true
                                        storeRename = true
                                    } label: {
                                        Text("Rename")
                                    }
                                    .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
                                }
                                .if(stores.count > 1 && storeSelection != storeItem.id) { view in
                                    view
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deleteStore(storeId: storeItem.id)
                                            } label: {
                                                Text("Delete")
                                            }
                                        }
                                }
                            }
                            
                        } header: {
                            Text("All Stores")
                        }
                    }
                    .toolbar {
                        ToolbarItem {
                            Button {
                                storeRenameId = nil
                                storeRenameName = ""
                                presentAlert = true
                                storeRename = false
                            } label: {
                                Label("Add Item", systemImage: "plus")
                            }
                        }
                    }
                    .navigationTitle(Text("Stores"))
                } detail: {
                    Text("Select a store")
                }
            }
            Tab("Items", systemImage: "list.dash") {
                
            }
            Tab("Recipes", systemImage: "star") {
                
            }
            Tab("Cart", systemImage: "cart") {
                
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
    }
    
    private func getStoreName(storeId: UUID?) -> String {
        for store in stores where store.id == storeId {
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
            for store in stores where store.id == storeId {
                store.name = newName
                break
            }
        }
    }
    
    private func deleteStore(storeId: UUID) {
        withAnimation {
            for store in stores where store.id == storeId {
                modelContext.delete(store)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Store.self], inMemory: true)
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension String {
    func trim() -> String {
    return self.trimmingCharacters(in: .whitespaces)
   }
}
