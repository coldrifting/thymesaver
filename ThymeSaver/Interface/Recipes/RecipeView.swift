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
        let recipeSections = splitRecipes(recipes: recipes)
        
        ForEach(recipeSections, id: \.title) { section in
            recipeList(title: section.title, recipes: section.recipes)
        }

    }
    
    @ViewBuilder
    private func recipeList(title: String, recipes: [Recipe]) -> some View {
        if (!recipes.isEmpty) {
            Section(title) {
                ForEach(recipes) { recipe in
                    Text(recipe.recipeName)
                    .swipeActions(edge: .leading) {
                        Button(
                            action: {
                                viewModel.toggleRecipePin(recipeId: recipe.recipeId)
                            },
                            label: { Text(recipe.isPinned ? "Unpin" : "Pin") }
                        )
                        .tint(.orange)
                        Button(
                            action: { viewModel.queueRenameItemAlert(itemId: recipe.recipeId, itemName: recipe.recipeName) },
                            label: { Text("Rename") }
                        )
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
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
    }
    
    private func splitRecipes(recipes: [Recipe]) -> [(title: String, recipes: [Recipe])]{
        var pinnedRecipes: [Recipe] = []
        var unpinnedRecipes: [Recipe] = []
        
        for recipe in recipes {
            if recipe.isPinned {
                pinnedRecipes.append(recipe)
            } else {
                unpinnedRecipes.append(recipe)
            }
        }
        
        return [
            ("Pinned", pinnedRecipes),
            ("Unpinned", unpinnedRecipes)
        ]
    }
}


#Preview {
    RecipeView(.shared)
}
