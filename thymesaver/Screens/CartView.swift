import SwiftUI
import SwiftData

struct CartView: View {
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
    CartView()
        .modelContainer(for: [Store.self], inMemory: true)
}
