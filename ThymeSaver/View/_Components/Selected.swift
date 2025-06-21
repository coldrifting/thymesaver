import SwiftUI

struct Selected: View {
    let name: String
    let selected: Bool
    
    init(name: String, selected: Bool) {
        self.name = name
        self.selected = selected
    }
    
    var body: some View {
        HStack {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
                .accessibilityLabel(selected ? "Selected" : "Unselected")
                .padding([.trailing], 4)
            Text(name)
        }
    }
}
