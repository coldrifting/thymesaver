import SwiftUI
import Observation
import Combine

struct ItemsView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    @State private var itemsWithAisleInfo: [(section: String, items: [ItemExpanded])] = []
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack {
            List {
                itemsList()
            }
            .navigationTitle(Text("Items"))
            .searchable(text: viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: { viewModel.cycleSectionSplitType() },
                        label: { Label("Sort By: \(viewModel.sectionSplitType)", systemImage: getSortIcon()) }
                    )
                }
                ToolbarItem {
                    Button(
                        action: { viewModel.queueAddItemAlert() },
                        label: { Label("Add Item", systemImage: "plus") }
                    )
                }
            }
            .onAppear {
                viewModel.observe(filterText: viewModel.searchText.wrappedValue)
            }
            .onReceive(Just(viewModel.itemsWithAisleInfo)) { items in
                withAnimation {
                    self.itemsWithAisleInfo = items
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
    
    private func getSortIcon() -> String {
        return switch viewModel.sectionSplitType {
        case .none: "textformat"
        case .temp: "thermometer.snowflake"
        case .aisle: "location"
        }
    }

    @ViewBuilder
    private func itemsList() -> some View {
        ForEach(itemsWithAisleInfo, id: \.section) { (section, sectionItemsList) in
            Section(section) {
                sectionItems(items: sectionItemsList)
            }
        }
    }
    
    private func sectionItems(items: [ItemExpanded], ) -> some View {
        ForEach(items) { item in
            NavigationLink(
                destination: { ItemDetailsView(appDatabase, itemId: item.itemId, itemName: item.itemName) },
                label: {
                    HStack {
                        Text(item.itemName)
                        Spacer()
                        
                        let secondaryText = viewModel.sectionSplitType != .aisle
                        ? item.aisleName ?? ""
                        : item.itemTemp.description
                        
                        Text(secondaryText).foregroundStyle(.secondary).font(.system(size: 15))
                    }
                }
            )
            .swipeActions(edge: .leading) {
                Button(
                    action: { viewModel.queueRenameItemAlert(itemId: item.itemId, itemName: item.itemName) },
                    label: { Text("Rename") }
                )
                .tint(.blue)
            }
            .if(item.usedIn.count > 0) { v in
                v
                .swipeActions(edge: .trailing) {
                    Button(
                        action: {
                            viewModel.queueDeleteItemAlert(itemId: item.itemId, itemsInUse: item.usedIn)
                        },
                        label: { Text("Delete") }
                    )
                    .tint(.red)
                }
            }
            .deleteDisabled(item.usedIn.count > 0)
        }
        .onDelete { offsets in
            offsets.forEach { index in
                viewModel.deleteItem(itemId: items[index].itemId)
            }
        }
    }
}


#Preview {
    ItemsView(.shared)
}
