import SwiftUI

struct CheckboxItem: View {
    var isChecked: Bool
    var onToggle: () -> Void
    var text: String
    var subtitle: String?
    var subsubtitle: String?
    
    init(isChecked: Bool,
         onToggle: @escaping () -> Void,
         text: String,
         subtitle: String? = nil,
         subsubtitle: String? = nil
    ) {
        self.isChecked = isChecked
        self.onToggle = onToggle
        self.text = text
        self.subtitle = subtitle
        self.subsubtitle = subsubtitle
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
                    if let subtitle = subtitle {
                        VStack(alignment: .trailing) {
                            Text(subtitle)
                            if let subsubtitle = subsubtitle {
                                Text(subsubtitle).font(.caption)
                            }
                        }
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .backgroundStyle(.secondary)
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
