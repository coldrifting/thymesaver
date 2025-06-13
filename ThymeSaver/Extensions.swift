import SwiftUI
import SwiftData

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension String {
    func trim() -> String {
    return self.trimmingCharacters(in: .whitespaces)
   }
}

extension UUID {
    init(number: Int64) {
        var number = number
        let numberData = Data(bytes: &number, count: MemoryLayout<Int64>.size)
        
        let bytes = [UInt8](numberData)
        
        let tuple: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0,
                             bytes[0], bytes[1], bytes[2], bytes[3],
                             bytes[4], bytes[5], bytes[6], bytes[7])
        
        self.init(uuid: tuple)
    }
}

extension View {
    func customAlert(
        title: String,
        message: String,
        placeholder: String,
        onConfirm: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void,
        alertType: AlertType,
        @Binding text: String
    ) -> some View {
        self.alert(
            title,
            isPresented: Binding<Bool>(get: { alertType != AlertType.none}, set: {_ in onDismiss()}),
            actions: {
                TextField(placeholder, text: $text)
                
                Button(alertType.description, action: {
                    withAnimation {
                        onConfirm(text.trim())
                    }
                })
                Button("Cancel", role: .cancel, action: {
                })
            },
            message: { Text(message) })
    }
}
