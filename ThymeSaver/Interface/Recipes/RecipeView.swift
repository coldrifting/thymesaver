import SwiftUI

struct RecipeView: View {
    @State private var viewModel: ViewModel
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("TODO") {
                    Text("TODO")
                }
            }
            .navigationTitle(Text("Recipes"))
        }
    }
}


#Preview {
    RecipeView(.shared)
}
