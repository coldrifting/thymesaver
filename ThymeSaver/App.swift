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
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Stores", systemImage: "location", value: 0) {
                StoreView(appDatabase)
            }
            Tab("Items", systemImage: "list.dash", value: 1) {
                ItemView(appDatabase)
            }
            Tab("Recipes", systemImage: "star", value: 2) {
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
