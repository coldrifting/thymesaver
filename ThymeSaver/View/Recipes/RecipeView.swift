import SwiftUI
import Observation
import Combine

struct RecipeView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    @State private var recipes: [Recipe] = []
    
    @State private var isInEditMode: Bool = false
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack {
            List {
                allRecipes()
            }
            .toolbar {
                ToolbarItem() {
                    Button(
                        action: { $isInEditMode.wrappedValue = !isInEditMode },
                        label: { Text(isInEditMode ? "Done" : "Edit") }
                    )
                }
                ToolbarItem {
                    Button(
                        action: { viewModel.alert.queueAdd() },
                        label: { Label("Add Item", systemImage: "plus") }
                    )
                }
            }
            .onAppear(perform: viewModel.observe)
            .onReceive(Just(viewModel.recipes)) { recipes in
                withAnimation {
                    self.recipes = recipes
                }
            }
            .navigationTitle(Text("Recipes"))
            .alertCustom(viewModel.alert)
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
                        if (isInEditMode) {
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
                            action: { viewModel.alert.queueRename(id: recipe.recipeId, name: recipe.recipeName) },
                            label: { Text("Rename") }
                        )
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(
                            action: {
                                viewModel.alert.queueDelete(id: recipe.recipeId, itemsInUse: ["Test", "test2"])
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
