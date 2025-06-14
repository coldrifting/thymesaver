import SwiftUI
import Observation
import Combine

public struct FilterSelectionPicker: View {
    private let title: String
    private let selection: Binding<Int>
    private let options: [(id: Int, name: String)]
    
    public init(
        _ title: String,
        selection: Binding<Int>,
        options: [(id: Int, name: String)]
    ) {
        self.title = title
        self.selection = selection
        self.options = options
    }
    
    public var body: some View {
        NavigationLink {
            FilterSelectionPickerModal(title, selection: selection, options: options)
        } label: {
            let selectionText = options.first(where: { $0.id == selection.wrappedValue })?.name ?? "(Unset)"
            VStack {
                Button(
                    action: { },
                    label: {
                        HStack {
                            Text(title)
                            Spacer()
                            Text(verbatim: selectionText).foregroundStyle(.secondary)
                        }
                    }
                )
                .foregroundStyle(.primary)
            }
        }
    }
    
    private struct FilterSelectionPickerModal: View {
        @Environment(\.dismiss) private var dismiss
        
        @State private var filterText: String = ""
        
        private let title: String
        private let selection: Binding<Int>
        private let options: [(id: Int, name: String)]
        
        
        public init(
            _ title: String,
            selection: Binding<Int>,
            options: [(id: Int, name: String)]
        ) {
            self.title = title
            self.selection = selection
            self.options = options
        }
        
        func filter(_ isIncluded: any StringProtocol) -> Bool {
            return self.filterText.trim().isEmpty ||
            isIncluded.lowercased().trim().contains(self.filterText.lowercased().trim())
        }
        
        var body: some View {
            List {
                ForEach(options.filter{ filter($0.name) }, id: \.id) { option in
                    Button(
                        action: {
                            self.selection.wrappedValue = option.id
                            dismiss()
                        },
                        label: {
                            HStack {
                                Text(option.name)
                                if (self.selection.wrappedValue == option.id) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .font(.body.weight(.semibold))
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    ).foregroundStyle(.primary)
                }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $filterText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}
