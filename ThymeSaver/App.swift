import SwiftUI
import Observation
import GRDB

/*
let schemaTypes : [any PersistentModel.Type] = [
    StoreOld.self,
    Aisle.self,
    Item.self
]
let schema = Schema(schemaTypes)
*/

@main
struct thymesaverApp: App {
    /*
    var sharedModelContainer: ModelContainer = {
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            var itemFetchDescriptor = FetchDescriptor<Store>()
            itemFetchDescriptor.fetchLimit = 1
            
            guard try container.mainContext.fetch(itemFetchDescriptor).count == 0 else { return container }
            
            populate(context: container.mainContext)
            
            try container.mainContext.save()
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    */
    
    var dbQueue: DatabaseQueue = {
        return grdb()
    }()
    
    var body: some Scene {
        WindowGroup {
            AppContentView().appDatabase(.shared)
        }
        //.modelContainer(for: schemaTypes)
    }
}


struct AppContentView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Stores", systemImage: "location", value: 0) {
                StoreView(appDatabase: appDatabase)
            }
            Tab("Items", systemImage: "list.dash", value: 1) {
                //ItemView()
            }
            Tab("Recipes", systemImage: "star", value: 2) {
                //RecipeView()
            }
            Tab("Cart", systemImage: "cart", value: 3) {
                //CartView()
            }
        }
    }
    
}

extension EnvironmentValues {
    @Entry var appDatabase = AppDatabase.empty()
}

extension View {
    func appDatabase(_ appDatabase: AppDatabase) -> some View {
        self.environment(\.appDatabase, appDatabase)
    }
}



/*
@MainActor
let previewContainer: ModelContainer = {
    do {
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        populate(context: container.mainContext)
        
        return container
    } catch {
        fatalError("Failed to create container")
    }
}()
*/
#Preview {
    AppContentView()
        //.modelContainer(previewContainer)
}
