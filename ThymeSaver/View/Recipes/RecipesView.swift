import SwiftUI
import Observation
import Combine

struct RecipesView: View {
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
                    HStack {
                        Button(
                            action: { $isInEditMode.wrappedValue = !isInEditMode },
                            label: {
                                Label($isInEditMode.wrappedValue ? "Done" : "Edit" , systemImage: $isInEditMode.wrappedValue ? "xmark" : "pencil")
                            }
                        )
                        .tint($isInEditMode.wrappedValue ? .red : .accentColor)
                        Button(
                            action: { viewModel.alert.queueAdd() },
                            label: { Label("Add Item", systemImage: "plus") }
                        )
                    }
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
                                        withAnimation {
                                            viewModel.toggleRecipePin(recipeId: recipe.recipeId)
                                        }
                                    },
                                    label: { Label("Pin", systemImage: recipe.isPinned ? "star.fill" : "star").labelStyle(.iconOnly) }
                                )
                                .padding(.trailing).frame(width: 20, height: 0)
                                Text(recipe.recipeName)
                        }
                        else {
                            NavigationLink(
                                destination: { RecipeIngredientsView(appDatabase, recipeId: recipe.recipeId, recipeName: recipe.recipeName) },
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
                    .deleteDisabled(recipe.isPinned)
                }
                .onDelete { offsets in
                    offsets.forEach { index in
                        viewModel.deleteRecipe(recipeId: self.recipes[index].recipeId)
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
    RecipesView(.shared)
}
