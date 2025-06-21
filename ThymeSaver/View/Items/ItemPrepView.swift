import SwiftUI
import Observation
import Combine

struct ItemPrepView: View {
    @State private var viewModel: ViewModel
    
    @State private var allPreps: [Prep] = []
    
    init(_ appDatabase: AppDatabase, itemId: Int, itemName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase, itemId: itemId, itemName: itemName))
    }
    
    var body: some View {
        List {
            ForEach(self.allPreps) { itemPrep in
                let deleteMsg: [String] = viewModel.prepRecipeInfo[itemPrep.prepId] ?? []
                let selected: Bool = viewModel.itemPreps.contains(itemPrep)
                Button(
                    action: {
                        withAnimation {
                            if (selected) {
                                viewModel.unselectPrep(prep: itemPrep)
                            }
                            else {
                                viewModel.selectPrep(prep: itemPrep)
                            }
                        }
                    },
                    label: {
                        HStack {
                            Selected(name: itemPrep.description, selected: selected)
                        }
                    }
                )
                .foregroundStyle(.primary)
                .swipeActions(edge: .leading) {
                    Button(
                        action: { viewModel.alert.queueRename(id: itemPrep.prepId, name: itemPrep.description)},
                        label: { Text("Rename") }
                    )
                    .tint(.blue)
                }
                .if(!deleteMsg.isEmpty) { v in
                    v.swipeActions(edge: .trailing) {
                        Button(
                            action: { viewModel.alert.queueDelete(id: itemPrep.prepId, itemsInUse: deleteMsg) },
                            label: { Text("Delete") }
                        )
                        .tint(.red)
                    }
                }
                .deleteDisabled(!deleteMsg.isEmpty)
            }
            .onDelete { offsets in
                offsets.forEach { index in
                    viewModel.deletePrep(prepId: self.allPreps[index].prepId)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    action: { viewModel.alert.queueAdd() },
                    label: { Label("Add Preperation", systemImage: "plus") }
                )
            }
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Preperations").font(.headline)
                    Text(viewModel.itemName).font(.subheadline)
                }
            }
        }
        .toolbar {
            // Hack to force back title to always display for navigation bar
            ToolbarItem(placement: .topBarLeading) {
                Button { } label: {
                    Color.clear
                }

            }
        }
        .navigationTitle("Preperations").navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.observe() }
        .onReceive(Just(viewModel.allPreps)) { allProps in
            self.allPreps = allProps
        }
        .alertCustom(viewModel.alert)
    }
}

#Preview {
    NavigationStack {
        ItemPrepView(.shared, itemId: 207, itemName: "Cucumbers")
    }
}
