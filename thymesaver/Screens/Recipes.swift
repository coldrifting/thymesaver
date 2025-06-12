import SwiftUI
import SwiftData

struct Recipes: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationSplitView {
            List {
                Button("Add Recipe") {
                    
                }
            }
            .navigationTitle(Text("Recipes"))
        } detail: {
            Text("Select a Recipe")
        }
    }
}

#Preview {
    Recipes()
        .modelContainer(for: [Store.self], inMemory: true)
}
