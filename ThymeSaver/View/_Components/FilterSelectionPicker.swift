import SwiftUI
import Observation
import Combine

public struct FilterSelectionPicker<T: Identifiable & CustomStringConvertible>: View {
    private let title: String
    private let selection: Binding<T?>
    private let options: [T]
    private let getSubtitle: ((T) -> String?)?
    private let subTitleLabel: String?
    
    public init(
        _ title: String,
        selection: Binding<T?>,
        options: [T],
        getSubtitle: ((T) -> String?)? = nil,
        subTitleLabel: String? = nil
    ) {
        self.title = title
        self.selection = selection
        self.options = options
        self.getSubtitle = getSubtitle
        self.subTitleLabel = subTitleLabel
    }
    
    public var body: some View {
        NavigationLink(
            destination: {
                FilterSelectionPickerModal(title, selection: selection, options: options, getSubtitle: getSubtitle)
            },
            label: {
                let selectionText = options.first(where: {$0.id == selection.wrappedValue?.id })?.description ?? "(Unset)"
                VStack {
                    HStack {
                        Text(title)
                        Spacer()
                        Text(selectionText).foregroundStyle(.secondary)
                    }
                    if let subTitleLabel {
                        if let selection = selection.wrappedValue {
                            if let getSubtitle {
                                if let caption = getSubtitle(selection) {
                                    Divider()
                                    HStack {
                                        Text(subTitleLabel)
                                        Spacer()
                                        Text(caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        )
    }
    
    struct FilterSelectionPickerModal: View {
        @Environment(\.dismiss) private var dismiss
        
        @State private var filterText: String = ""
        
        private let title: String
        private let selection: Binding<T?>
        private let options: [T]
        private let getSubtitle: ((T) -> String?)?
        
        public init(
            _ title: String,
            selection: Binding<T?>,
            options: [T],
            getSubtitle: ((T) -> String?)? = nil
        ) {
            self.title = title
            self.selection = selection
            self.options = options
            self.getSubtitle = getSubtitle
        }
        
        func getText(_ option: T) -> String {
            let text: String = option.description
            if let getSubtitle {
                let caption: String? = getSubtitle(option)
                if let caption {
                    return "\(text) - \(caption)"
                }
            }
            return text
        }
        
        func filter(_ isIncluded: any StringProtocol) -> Bool {
            return self.filterText.trim().isEmpty ||
            isIncluded.lowercased().trim().contains(self.filterText.lowercased().trim())
        }
        
        var body: some View {
            List {
                Section("Aisles") {
                    let optionsFiltered: [T] = options.filter{ opt in self.filter(getText(opt)) }
                    
                    ForEach(optionsFiltered) { option in
                        Button(
                            action: {
                                self.selection.wrappedValue = option
                                dismiss()
                            },
                            label: {
                                HStack {
                                    let text: String = getText(option)
                                    Text(text)
                                    if (self.selection.wrappedValue?.id == option.id) {
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
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .searchable(text: $filterText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}
