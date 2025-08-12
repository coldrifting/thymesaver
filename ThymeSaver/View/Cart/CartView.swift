import SwiftUI
import Observation
import Combine

struct CartView: View {
    @State private var viewModel: ViewModel
    
    @State private var cartAisles: [CartAisle] = []
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        List {
            ForEach(self.cartAisles) { cartAisle in
                Section(cartAisle.aisleName) {
                    ForEach(cartAisle.entries) { entry in
                        CheckboxItem(
                            isChecked: entry.checked,
                            onToggle: { viewModel.toggleCartEntryChecked(entryId: entry.cartEntryId) },
                            text: entry.itemName,
                            subtitle: entry.itemAmount.description
                        )
                    }
                }
            }
        }
        .navigationTitle("Cart").navigationBarTitleDisplayMode(.inline)
        .onAppear{ viewModel.observe() }
        .onReceive(Just(viewModel.cartAisles)) { cartAisles in
            withAnimation {
                self.cartAisles = cartAisles
            }
        }
    }
}

#Preview {
    NavigationStack {
        CartView(.shared)
    }
}
