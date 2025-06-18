import SwiftUI

struct CartView: View {
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
            .navigationTitle(Text("Cart"))
        }
    }
}


#Preview {
    CartView(.shared)
}
