import SwiftUI

struct ItemView: View {
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
            .navigationTitle(Text("Items"))
        }
    }
}


#Preview {
    ItemView(.shared)
}
