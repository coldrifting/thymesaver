import SwiftUI
import Observation
import Combine

struct RecipeView: View {
    @State private var viewModel: ViewModel
    
    @State private var recipes: [Recipe] = []
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack {
            List {
                allRecipes()
            }
            .toolbar {
                ToolbarItem {
                    Button(
                        action: { viewModel.queueAddItemAlert() },
                        label: { Label("Add Item", systemImage: "plus") }
                    )
                }
            }
            .navigationTitle(Text("Recipes"))
            .onAppear(perform: viewModel.observe)
            .onReceive(Just(viewModel.recipes)) { recipes in
                withAnimation {
                    self.recipes = recipes
                }
            }
            .customAlert(
                title: viewModel.alertTitle,
                message: viewModel.alertMessage,
                placeholder: viewModel.alertPlaceholder,
                onConfirm: { stringValue in
                    switch viewModel.alertType {
                    case .add:
                        viewModel.addRecipe(recipeName: stringValue)
                    case .rename:
                        viewModel.renameRecipe(recipeId: viewModel.alertId, newName: stringValue)
                    case .delete:
                        viewModel.deleteRecipe(recipeId: viewModel.alertId)
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
    
    @ViewBuilder
    private func allRecipes() -> some View {
        ForEach(recipes) { recipe in
            Text(recipe.recipeName)
            .swipeActions(edge: .leading) {
                Button(
                    action: { viewModel.queueRenameItemAlert(itemId: recipe.recipeId, itemName: recipe.recipeName) },
                    label: { Text("Rename") }
                )
                .tint(.blue)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(
                    action: {
                        viewModel.queueDeleteItemAlert(itemId: recipe.recipeId, itemsInUse: ["Test", "test2"])
                    },
                    label: { Text("Delete") }
                )
                .tint(.red)
            }
        }
    }
}


#Preview {
    RecipeView(.shared)
}
