import SwiftUI
import Observation
import GRDB

@main
struct thymesaverApp: App {
    var body: some Scene {
        WindowGroup {
            AppContentView().appDatabase(.shared)
        }
    }
}

struct AppContentView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var selectedTab: Int = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Stores", systemImage: "location", value: 0) {
                StoreView(appDatabase)
            }
            Tab("Items", systemImage: "square.stack.3d.down.right", value: 1) {
                ItemsView(appDatabase)
            }
            Tab("Recipes", systemImage: "list.bullet.rectangle", value: 2) {
                RecipeView(appDatabase)
            }
            Tab("Cart", systemImage: "cart", value: 3) {
                CartView(appDatabase)
            }
        }
    }
    
}

extension EnvironmentValues {
    @Entry var appDatabase = AppDatabase.shared
}

extension View {
    func appDatabase(_ appDatabase: AppDatabase) -> some View {
        self.environment(\.appDatabase, appDatabase)
    }
}

#Preview {
    AppContentView().appDatabase(.shared)
}
