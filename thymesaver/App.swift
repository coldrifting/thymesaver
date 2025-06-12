import SwiftUI
import SwiftData

@main
struct thymesaverApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Store.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}


struct AppContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TabView {
            Tab("Stores", systemImage: "location") {
                Stores()
            }
            Tab("Items", systemImage: "list.dash") {
                Items()
            }
            Tab("Recipes", systemImage: "star") {
                Recipes()
            }
            Tab("Cart", systemImage: "cart") {
                Cart()
            }
        }
    }
    
}

#Preview {
    AppContentView()
        .modelContainer(for: [Store.self], inMemory: true)
}
