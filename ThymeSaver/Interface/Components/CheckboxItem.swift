import SwiftUI

struct CheckboxItem: View {
    var isChecked: Bool
    var onToggle: () -> Void
    var text: String
    var subtitle: String?
    
    init(isChecked: Bool,
         onToggle: @escaping () -> Void,
         text: String, subtitle: String? = nil) {
        self.isChecked = isChecked
        self.onToggle = onToggle
        self.text = text
        self.subtitle = subtitle
    }
    
    var body: some View {
        Button(
            action: {
                withAnimation {
                    onToggle()
                }
            },
            label: {
                HStack {
                    Text(text)
                    Spacer()
                    if (subtitle != nil) {
                        Text(subtitle ?? "").foregroundStyle(.secondary).font(.footnote)
                    }
                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                        .accessibilityLabel(isChecked ? "Selected" : "Unselected")
                }
            },
        )
        .foregroundStyle(.primary)
    }
}
