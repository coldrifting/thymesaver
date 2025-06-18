import SwiftUI

@Observable @MainActor
class AlertViewModel {
    enum AlertType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
        case none
        case add
        case rename
        case delete
        
        var id: Self { self }
        
        var description: String {
            return self.rawValue.capitalized
        }
    }
    
    init(
        itemName: String,
        addAction: ((String) -> ())? = nil,
        renameAction: ((Int, String) -> ())? = nil,
        deleteAction: ((Int) -> ())? = nil
    ) {
        self.itemName = itemName
        self.placeholder = "\(itemName) Name"
        self.addAction = addAction
        self.renameAction = renameAction
        self.deleteAction = deleteAction
    }
    
    private(set) var addAction: ((String) -> Void)?
    private(set) var renameAction: ((Int, String) -> Void)?
    private(set) var deleteAction: ((Int) -> Void)?
    
    private(set) var itemId: Int = -1
    
    private(set) var itemName: String
    private(set) var placeholder: String
    
    private(set) var title: String = ""
    private(set) var message: String? = nil
    
    private(set) var confirmText: String = ""
    private(set) var DismissText: String = "Cancel"
    
    private(set) var type: AlertType = AlertType.none
    var isShown: Binding<Bool> {
        Binding(
            get: { self.type != .none },
            set: { if ($0 == false) { self.type = .none } }
        )
    }
    
    private var _textEntry: String = ""
    var textEntry: Binding<String> {
        Binding(
            get: { self._textEntry },
            set: { self._textEntry = $0 }
        )
    }
    
    func confirmAction() {
        switch self.type {
        case .none:
            break
        case .add:
            if let action = self.addAction {
                action(self._textEntry)
            }
        case .rename:
            if let action = self.renameAction {
                action(self.itemId, self._textEntry)
            }
        case .delete:
            if let action = self.deleteAction {
                action(self.itemId)
            }
        }
    }
    
    func queueAdd() {
        self.itemId = -1
        self._textEntry = ""
        self.title = "Add \(self.itemName)"
        self.message = nil
        self.confirmText = "Add"
        self.type = .add
    }
    
    func queueRename(id: Int, name: String) {
        self.itemId = id
        self._textEntry = name
        self.title = "Rename \(self.itemName)"
        self.message = nil
        self.confirmText = "Rename"
        self.type = .rename
    }
    
    func queueDelete(id: Int, itemsInUse: [String]? = nil) {
        
        if let itemsInUse = itemsInUse {
            let itemsInUseString: String = itemsInUse.count > 8
            ? itemsInUse.prefix(8).joined(separator: "\n") + "\n..."
            : itemsInUse.joined(separator: "\n")
            
            self.message = "The following recipes use this item: \n \(itemsInUseString)"
        }
        
        self.itemId = id
        self.title = "Delete \(self.itemName)?"
        self.confirmText = "Delete"
        self.type = .delete
    }
    
    func dismiss() {
        self.itemId = -1
        self._textEntry = ""
        self.type = .none
    }
}

extension View {
    func alertCustom(_ alert: AlertViewModel) -> some View {
        return self.alert(
            alert.title,
            isPresented: alert.isShown,
            actions: {
                if (alert.type != .delete) {
                    TextField(alert.placeholder, text: alert.textEntry)
                }
                
                Button(alert.type.description, role: alert.type == .delete ? .destructive : .none, action: {
                    withAnimation {
                        alert.confirmAction()
                    }
                })
                
                Button("Cancel", role: .cancel, action: { } )
            },
            message: {
                if let message = alert.message {
                    Text(message)
                }
            }
        )
    }
}
