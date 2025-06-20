import SwiftUI


struct ListButton<Content: View> : View {
    var role: ButtonRole?
    var action: () -> Void
    var label: () -> Content
    
    init(
        role: ButtonRole? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Content,
    ) {
        self.role = role
        self.action = action
        self.label = label
    }
    
    var body: some View {
        VStack {
            Button(
                role: role,
                action: action,
                label: {
                    label()
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .padding([.leading, .trailing], 8)
                }
            )
            .buttonStyle(.borderedProminent)
        }
        .buttonStyle(.plain)
        .listRowBackground(EmptyView())
        .listRowInsets(EdgeInsets())
    }
}
