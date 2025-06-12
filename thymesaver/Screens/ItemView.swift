import SwiftUI
import SwiftData

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationSplitView {
            List {
                Button("Add Item") {
                    
                }
            }
            .navigationTitle(Text("Items"))
        } detail: {
            Text("Select an Item")
        }
    }
}

#Preview {
    ItemView()
        .modelContainer(for: [Store.self], inMemory: true)
}
