import SwiftUI
import SwiftData

struct ItemDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    
    private var itemId: UUID
    
    @Query private var items: [Item]
    @Query private var itemsFiltered: [Item]
    
    @State private var itemName: String
    @State private var itemTemp: ItemTemp
    @State private var defaultUnits: UnitType
    
    init(itemId: UUID, itemTemp: ItemTemp, defaultUnits: UnitType, itemName: String) {
        self.itemId = itemId
        
        self.itemTemp = itemTemp
        self.defaultUnits = defaultUnits
        self.itemName = itemName
        
        _itemsFiltered = Query(filter: #Predicate<Item> { itemId == $0.uuid })
    }
    
    var body: some View {
        if let selectedItem = itemsFiltered.first {
            List {
                Section("Details") {
                    // TODO - Debounce?
                    TextField(selectedItem.name, text: $itemName)
                    
                    // TODO - Make animations work
                    Picker("Temperature", selection: $itemTemp) {
                        ForEach(ItemTemp.allCases, id: \.self) { option in
                            Text(String(describing: option).capitalized).tag(option)
                        }
                    }
                    
                    Picker("Default Units", selection: $defaultUnits) {
                        ForEach(UnitType.allCases, id: \.self) { option in
                            Text(String(describing: option).capitalized).tag(option)
                        }
                    }
                }
                
                Section("Location") {
                    Text("TODO") // TODO
                }
                
                Section("Preperations") {
                    Text("TODO") // TODO
                }
            }.onChange(of: itemTemp, initial: true) { oldVal, newVal in
                setItemTemp(itemId: itemId, itemTemp: newVal)
            }.onChange(of: defaultUnits, initial: true) { oldVal, newVal in
                setItemDefaultUnits(itemId: itemId, defaultUnits: newVal)
            }.onChange(of: itemName, initial: true) { oldVal, newVal in
                setItemName(itemId: itemId, itemName: newVal)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        // TODO
                    } label: {
                        Label("Add Preperation", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(Text(selectedItem.name))
        }
        else {
            Text("Item not found")
        }
    }
    
    private func setItemName(itemId: UUID, itemName: String) {
        withAnimation {
            items.first(where: { $0.uuid == itemId })?.name = itemName
        }
    }
    
    private func setItemTemp(itemId: UUID, itemTemp: ItemTemp) {
        withAnimation {
            items.first(where: { $0.uuid == itemId })?.temp = itemTemp
        }
    }
    
    private func setItemDefaultUnits(itemId: UUID, defaultUnits: UnitType) {
        withAnimation {
            items.first(where: { $0.uuid == itemId })?.defaultUnits = defaultUnits
        }
    }
}
