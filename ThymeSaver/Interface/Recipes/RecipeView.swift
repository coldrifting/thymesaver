import SwiftUI
import Observation
import Combine

struct RecipeView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack {
            List {
                RecipeViewSubView(viewModel)
            }
            .toolbar {
                ToolbarItem() {
                    EditButton()
                }
                ToolbarItem {
                    Button(
                        action: { viewModel.queueAddItemAlert() },
                        label: { Label("Add Item", systemImage: "plus") }
                    )
                }
            }
            .onAppear(perform: viewModel.observe)
            .navigationTitle(Text("Recipes"))
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
}

struct RecipeViewSubView: View {
    @Environment(\.appDatabase) var appDatabase
    @Environment(\.editMode) var editMode
    
    @State private var viewModel: RecipeView.ViewModel
    @State private var recipes: [Recipe] = []
    
    init(_ viewModel: RecipeView.ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        allRecipes()
        .onReceive(Just(viewModel.recipes)) { recipes in
            withAnimation {
                self.recipes = recipes
            }
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
                    HStack {
                        if (editMode?.wrappedValue.isEditing == true) {
                            
                                Button(
                                    action: {
                                        viewModel.toggleRecipePin(recipeId: recipe.recipeId)
                                    },
                                    label: { Label("Pin", systemImage: recipe.isPinned ? "star.fill" : "star").labelStyle(.iconOnly) }
                                )
                                .padding(.trailing).frame(width: 20, height: 0)
                                Text(recipe.recipeName)
                        }
                        else {
                            NavigationLink(
                                destination: { RecipeDetailsView(appDatabase, recipeId: recipe.recipeId, recipeName: recipe.recipeName) },
                                label: { Text(recipe.recipeName) }
                            )
                        }
                    }
                    .swipeActions(edge: .leading) {
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
