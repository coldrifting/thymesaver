import SwiftUI
import SwiftData

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
