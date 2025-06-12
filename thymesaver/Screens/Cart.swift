import SwiftUI
import SwiftData

struct Cart: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationSplitView {
            List {
                Button("Setup Cart") {
                    
                }
            }
            .navigationTitle(Text("Cart"))
        } detail: {
            Text("Setup Cart")
        }
    }
}

#Preview {
    Cart()
        .modelContainer(for: [Store.self], inMemory: true)
}
