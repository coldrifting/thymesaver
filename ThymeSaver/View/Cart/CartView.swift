import SwiftUI
import Observation
import Combine

struct CartView: View {
    @State private var viewModel: ViewModel
    
    @State private var cartAisles: [CartAisle] = []
    @State private var checked: [Int:Bool] = [:]
    
    init(_ appDatabase: AppDatabase) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
    }
    
    var body: some View {
        List {
            ForEach(self.cartAisles) { cartAisle in
                Section(cartAisle.aisleName) {
                    let items: [(id: Int, item: Item)] = cartAisle.items.map {
                        let id = $0.itemId.concat($0.cartAmount?.id ?? -1)
                        return (id: id, item: $0)
                    }
                    
                    ForEach(items, id: \.id) { item in
                        let isChecked: Bool = self.checked[item.id] ?? false
                        CheckboxItem(
                            isChecked: isChecked,
                            onToggle: { viewModel.staticProperties.checked[item.id] = !isChecked },
                            text: item.item.itemName,
                            subtitle: item.item.cartAmount?.description)
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
        .onReceive(Just(viewModel.staticProperties.checked)) { checked in
            withAnimation {
                self.checked = checked
            }
        }
    }
}

#Preview {
    NavigationStack {
        CartView(.shared)
    }
}
