import SwiftUI
import Observation
import Combine

struct CartSelectView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    @State private var selectedRecipes: [Recipe] = []
    @State private var selectedItems: [Item] = []
    
    @State private var path = NavigationPath()
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                ListButton(
                    action: {
                        viewModel.generate()
                        $path.wrappedValue.append("Generate")
                    },
                    label: {
                        HStack {
                            Text("Generate List")
                            Spacer()
                            Label("Arrow", systemImage: "chevron.right").labelStyle(.iconOnly)
                        }
                    }
                )
                .tint(.indigo.opacity(0.25))
                
                if (self.selectedRecipes.count > 0) {
                    Section("Recipes") {
                        ForEach(self.selectedRecipes) { recipe in
                            Button(
                                action: { viewModel.queueUpdateRecipe(recipe: recipe) },
                                label: {
                                    HStack {
                                        Text(recipe.recipeName)
                                        Spacer()
                                        Text("Qty: \(recipe.cartAmount)").foregroundStyle(.secondary)
                                    }
                                }
                            )
                            .foregroundStyle(.primary)
                        }
                        .onDelete { offsets in
                            offsets.forEach { index in
                                viewModel.removeFromCart(recipeId: selectedRecipes[index].recipeId)
                            }
                        }
                    }
                    
                }
                
                if (self.selectedItems.count > 0) {
                    Section("Items") {
                        ForEach(self.selectedItems) { item in
                            Button(
                                action: { viewModel.queueUpdateItem(item: item) },
                                label: {
                                    HStack {
                                        Text(item.itemName)
                                        Spacer()
                                        if let cartAmount = item.cartAmount {
                                            Text("Qt: \(cartAmount)").foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            )
                            .foregroundStyle(.primary)
                        }
                        .onDelete { offsets in
                            offsets.forEach { index in
                                viewModel.removeFromCart(itemId: selectedItems[index].itemId)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        action: { viewModel.queueAddRecipeOrItem() },
                        label: {  Label("Add", systemImage: "plus")  }
                    )
                }
            }
            .sheet(isPresented: viewModel.showBottomSheet) {
                bottomSheet()
                    .presentationDetents([.medium])
            }
            .navigationTitle(Text("List Setup"))
            .navigationDestination(for: String.self, destination: { value in
                CartView(appDatabase)
            })
            .onAppear(perform: viewModel.observe )
            .onReceive(Just(viewModel.selectedRecipes)) { selectedRecipes in
                withAnimation {
                    self.selectedRecipes = selectedRecipes
                }
            }
            .onReceive(Just(viewModel.selectedItems)) { selectedItems in
                withAnimation {
                    self.selectedItems = selectedItems
                }
            }
        }
    }
    
    @ViewBuilder
    func bottomSheet() -> some View {
        NavigationStack {
            List {
                if (!viewModel.inUpdateMode) {
                    Section("Type") {
                        Section {
                            Picker(
                                selection: $viewModel.isSelectionInRecipeMode,
                                content: {
                                    Text("Recipe").tag(true)
                                    Text("Item").tag(false)
                                },
                                label: {
                                    Text("Type")
                                }
                            )
                        }
                    }
                }
                
                let header: String = viewModel.isSelectionInRecipeMode == true
                ? "Recipe Details"
                : "Item Details"
                Section(header) {
                    if (!viewModel.inUpdateMode) {
                        if (viewModel.isSelectionInRecipeMode) {
                            FilterSelectionPicker(
                                "Recipe",
                                selection: viewModel.selectedRecipeToAdd,
                                options: viewModel.validRecipes
                            )
                        }
                        else {
                            FilterSelectionPicker(
                                "Item",
                                selection: viewModel.selectedItemToAdd,
                                options: viewModel.validItems
                            )
                        }
                    }
                    else {
                        if (viewModel.isSelectionInRecipeMode) {
                            HStack {
                                Text("Recipe")
                                Spacer()
                                Text(viewModel.selectedRecipeToAdd.wrappedValue?.recipeName ?? "").foregroundStyle(.secondary)
                            }
                        }
                        else {
                            HStack {
                                Text("Item")
                                Spacer()
                                Text(viewModel.selectedItemToAdd.wrappedValue?.itemName ?? "").foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    if (viewModel.isSelectionInRecipeMode) {
                        Stepper(
                            label: {
                                HStack {
                                    Text("Quantity")
                                    Spacer()
                                    Text(viewModel.selectedRecipeQuantity.wrappedValue.description)
                                }
                            },
                            onIncrement: { viewModel.selectedRecipeQuantity.wrappedValue += 1 },
                            onDecrement: { viewModel.selectedRecipeQuantity.wrappedValue -= 1 }
                        )
                    }
                    else {
                        AmountPicker(amount: viewModel.selectedItemAmount)
                    }
                }
                
                Section {
                    ListButton(
                        action: { viewModel.addOrUpdateRecipeOrItem() },
                        label: { Text(viewModel.addUpdateButtonText) }
                    )
                    .tint(viewModel.inUpdateMode ? .indigo : .blue)
                    .disabled(!viewModel.addUpdateButtonEnabled)
                }
            }
        }
    }
}

#Preview {
    CartSelectView(.shared)
}
