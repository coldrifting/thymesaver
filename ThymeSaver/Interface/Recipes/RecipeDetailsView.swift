import SwiftUI
import Observation
import Combine

struct RecipeDetailsView: View {
    @State private var viewModel: ViewModel
    
    @State private var recipeItems: RecipeTree = RecipeTree()
    
    @State private var isInEditMode: Bool = false
    @State private var showBottomSheet: Bool = false
    
    init(_ appDatabase: AppDatabase, recipeId: Int, recipeName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase, recipeId: recipeId, recipeName: recipeName))
    }
    
    var body: some View {
        List {
            Section("Steps") {
                NavigationLink(
                    destination: { EmptyView() },
                    label: { Text("Steps") }
                )
            }
            
            ForEach(recipeItems.recipeSections) { section in
                sectionContents(section)
            }
        }
        .toolbar {
            ToolbarItem() {
                Button(
                    action: { $isInEditMode.wrappedValue = !isInEditMode },
                    label: { Text(isInEditMode ? "Done" : "Edit") }
                )
            }
            if (isInEditMode) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(
                        action: {
                            viewModel.setupNewItemScreen()
                            showBottomSheet = true
                        },
                        label: { Label("Add", systemImage: "plus") }
                    )
                }
            }
        }
        .sheet(isPresented: $showBottomSheet, content: {
            NavigationStack {
                List {
                    Section() {
                        if (viewModel.recipeEntryAndItemId == nil && viewModel.recipeItems.recipeSections.count > 1) {
                            Picker("Section", selection: viewModel.selectedSectionIdBinding) {
                                ForEach(recipeItems.recipeSections, id: \.recipeSectionId) { recipeSection in
                                    Text(recipeSection.recipeSectionName).tag(recipeSection.recipeSectionName)
                                }
                            }
                        }
                        
                        FilterSelectionPicker(
                            "Ingredient",
                            selection: viewModel.selectedItemIdBinding,
                            options: viewModel.itemsFiltered
                        )
                    }
                    
                    Section("Amount") {
                        Picker("Unit Type", selection: viewModel.selectedUnitTypeBinding) {
                            ForEach(UnitType.allCases) { text in
                                Text(text.description).tag(text.description)
                            }
                        }
                        TextField("Unit Quantity", text: viewModel.selectedAmountBinding)
                    }
                    
                    VStack {
                        Button(
                            action: {
                                $showBottomSheet.wrappedValue = false
                                if let recipeEntryId = viewModel.recipeEntryAndItemId?.recipeEntryId {
                                    viewModel.updateRecipeEntry(recipeEntryId: recipeEntryId)
                                } else {
                                    viewModel.addRecipeEntry()
                                }
                            },
                            label: { Text(viewModel.recipeEntryAndItemId != nil ? "Update Ingredient" : "Add Ingredient")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }
                        )
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.recipeEntryAndItemId != nil ? .blue : .green.mix(with: .blue, by: 0.15).mix(with: .black, by: 0.15))
                        .disabled(!viewModel.selectedOkay)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(EmptyView())
                    .listRowInsets(EdgeInsets())
                }
            }.presentationDetents([.height(500)])
            
        })
        .navigationTitle(viewModel.recipeName).navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.observe )
        .onReceive(Just(viewModel.recipeItems)) { recipeItems in
            withAnimation {
                self.recipeItems = recipeItems
            }
        }
        .customAlert(
            title: viewModel.alertTitle,
            message: viewModel.alertMessage,
            placeholder: viewModel.alertPlaceholder,
            onConfirm: { stringValue in
                switch viewModel.alertType {
                case .add:
                    viewModel.addRecipeSection()
                case .rename:
                    viewModel.renameRecipeSection()
                case .delete:
                    break
                case .none:
                    break
                }
            },
            onDismiss: viewModel.dismissAlert,
            alertType: viewModel.alertType,
            $text: viewModel.alertTextBinding
        )
    }
    
    func showUpdateSheet(section: RecipeSectionTree, item: ItemTree) {
        viewModel.setupUpdateItemScreen(
            recipeEntryId: item.entryId,
            recipeSectionId: section.recipeSectionId,
            type: item.amount.type,
            fraction: item.amount.fraction,
            itemId: item.itemId)
        $showBottomSheet.wrappedValue = true
    }
    
    @ViewBuilder
    func sectionContents(_ section: RecipeSectionTree) -> some View {
        let headerText: String = recipeItems.recipeSections.count < 2 ? "Ingredients" : section.recipeSectionName
        Section(
            content: {
                ForEach(section.items) { item in
                    if (isInEditMode) {
                        HStack {
                            Text(item.itemName)
                            Spacer()
                            Button(
                                action: {
                                    showUpdateSheet(section: section, item: item)
                                },
                                label: {
                                    Text(item.amount.description)
                                        .font(.footnote)
                                        .frame(width: 50, height: 14)
                                }
                            )
                            .buttonStyle(.bordered).foregroundStyle(.primary)
                        }
                        .swipeActions(edge: .leading) {
                            Button(
                                action: {
                                    showUpdateSheet(section: section, item: item)
                                },
                                label: { Text("Update") }
                            )
                            .tint(.blue)
                        }
                    }
                    else {
                        CheckboxItem(
                            isChecked: item.isChecked,
                            onToggle: {
                                ViewModel.setValue(item.itemId.concat(item.itemPrep?.id ?? 1), value: !item.isChecked)
                                viewModel.update()
                            },
                            text: item.itemName,
                            subtitle: item.amount.description)
                        .deleteDisabled(true)
                    }
                }
                .onDelete { offsets in
                    offsets.forEach { index in
                        viewModel.deleteRecipeEntry(sectionIndex: section.recipeSectionId, index: index)
                    }
                }
            },
            header: {
                if (isInEditMode && viewModel.recipeItems.recipeSections.count > 1) {
                    Button(
                        action: { viewModel.queueRenameItemAlert(itemId: section.recipeSectionId, itemName: section.recipeSectionName) },
                        label: { Text(headerText).font(.footnote) }
                    )
                }
                else {
                    Text(headerText)
                }
            },
            footer: {
                if (isInEditMode && viewModel.recipeItems.recipeSections.last?.recipeSectionId == section.recipeSectionId) {
                    Button(
                        action: { viewModel.queueAddItemAlert() },
                        label: { Text("Add New Section").font(.footnote).textCase(.uppercase) }
                    )
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        RecipeDetailsView(.shared, recipeId: 2, recipeName: "Green Chili Mac & Cheese")
    }
}
