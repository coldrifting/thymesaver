import SwiftUI
import Observation
import Combine



struct FilterSelectionPicker<T: Identifiable & CustomStringConvertible>: View {
    fileprivate struct Details {
        let title: String
        let selection: Binding<T?>
        let options: [T]
        
        init(title: String, selection: Binding<T?>, options: [T]) {
            self.title = title
            self.selection = selection
            self.options = options
        }
    }
    
    private var details: Details
    
    init(_ title: String, selection: Binding<T?>, options: [T] ) {
        details = Details(
            title: title,
            selection: selection,
            options: options
        )
    }
    
    public var body: some View {
        NavigationLink(
            destination: {
                FilterSelectionPickerModalContainer(details)
            },
            label: {
                let selectionText = details.options.first(where: {$0.id == details.selection.wrappedValue?.id })?.description ?? "(Unset)"
                HStack {
                    Text(details.title)
                    Spacer()
                    Text(selectionText).foregroundStyle(.secondary)
                }
            }
        )
    }
    
    struct FilterSelectionPickerModalContainer: View {
        @Environment(\.dismiss) private var dismiss
        
        @State private var filterText: String = ""
        
        private var details: Details
        
        fileprivate init(_ details: Details) {
            self.details = details
        }
        
        func filter(_ isIncluded: any StringProtocol) -> Bool {
            return self.filterText.trim().isEmpty ||
            isIncluded.lowercased().trim().contains(self.filterText.lowercased().trim())
        }
        
        var body: some View {
            List {
                Section {
                    let optionsFiltered: [T] = details.options.filter{ opt in self.filter(opt.description) }
                    
                    ForEach(optionsFiltered) { option in
                        Button(
                            action: {
                                self.details.selection.wrappedValue = option
                                self.filterText = ""
                                dismiss()
                            },
                            label: {
                                HStack {
                                    let text: String = option.description
                                    Text(text)
                                    if (self.details.selection.wrappedValue?.id == option.id) {
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
            }
            .searchable(text: $filterText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(details.title).navigationBarTitleDisplayMode(.inline)
        }
    }
}
