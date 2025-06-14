import SwiftUI
import Observation
import Combine

struct AisleView: View {
    @State private var viewModel: ViewModel
    
    @State private var aisles: [Aisle] = []
    
    private var storeId: Int
    private var storeName: String
    
    init(_ appDatabase: AppDatabase, storeId: Int, storeName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase))
        self.storeId = storeId
        self.storeName = storeName
    }
    
    var body: some View {
        List {
            Section("Aisle Order") {
                allAisles()
            }
        }
        .navigationTitle(Text(storeName))
        .toolbar {
            ToolbarItem {
                EditButton()
            }
            ToolbarItem {
                Button(
                    action: { viewModel.queueAddItemAlert() },
                    label: { Label("Add Aisle", systemImage: "plus") }
                )
            }
        }
        .onAppear {
            viewModel.observe(storeId: self.storeId)
        }
        .onReceive(Just(viewModel.aisles)) { aisles in
            withAnimation {
                self.aisles = aisles
            }
        }
        .customAlert(
            title: viewModel.alertTitle,
            message: viewModel.alertMessage,
            placeholder: viewModel.alertPlaceholder,
            onConfirm: viewModel.alertType == AlertType.rename
            ? { viewModel.renameAisle(aisleId: viewModel.alertId, newName: $0)}
            : { viewModel.addAisle(aisleName: $0, storeId: storeId)},
            onDismiss: viewModel.dismissAlert,
            alertType: viewModel.alertType,
            $text: viewModel.alertTextBinding
        )
    }
    
    private func allAisles() -> some View {
        ForEach(aisles) { aisle in
            HStack {
                Text(aisle.aisleName)
                Spacer()
                Text("\(aisle.aisleOrder + 1)").foregroundStyle(.secondary)
            }
            .swipeActions(edge: .leading) {
                Button(
                    action: { viewModel.queueRenameItemAlert(itemId: aisle.aisleId, itemName: aisle.aisleName) },
                    label: { Text("Rename") }
                )
                .tint(Color(red: 0.2, green: 0.6, blue: 0.3))
            }
        }
        .onDelete { offsets in
            offsets.forEach { index in
                viewModel.deleteAisle(aisleId: aisles[index].aisleId, storeId: storeId)
            }
        }
        .onMove(perform: { indices, newOffset in
            var s = aisles.map({$0})
            s.move(fromOffsets: indices, toOffset: newOffset)
            for (index, item) in s.enumerated() {
                viewModel.moveAisle(aisleId: item.aisleId, newIndex: index)
            }
        })
    }
}


#Preview {
    AisleView(.shared, storeId: 0, storeName: "Test Store")
}
