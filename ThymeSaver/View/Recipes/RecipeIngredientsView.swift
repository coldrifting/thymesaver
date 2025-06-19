import SwiftUI
import Observation
import Combine

struct RecipeIngredientsView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    @State private var recipeItems: RecipeTree = RecipeTree()
    
    @State private var isInEditMode: Bool = true
    @State private var showBottomSheet: Bool = false
    
    @State private var test: Bool = false
    
    init(_ appDatabase: AppDatabase, recipeId: Int, recipeName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase, recipeId: recipeId, recipeName: recipeName))
    }
    
    var body: some View {
        List {
            
            Section("Details") {
                NavigationLink(
                    destination: { RecipeStepsView(appDatabase, recipeId: viewModel.recipeId, recipeName: viewModel.recipeName) },
                    label: { Text("Steps") }
                )
            }
            
            ForEach(recipeItems.recipeSections) { section in
                sectionContents(section)
            }
            
            if (isInEditMode) {
                Button("Add New Section") {
                    viewModel.alert.queueAdd()
                }
            }
        }
        .navigationTitle(viewModel.recipeName).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Recipe Ingredients").font(.headline)
                    Text(viewModel.recipeName).font(.subheadline)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(
                        action: { $isInEditMode.wrappedValue = !isInEditMode },
                        label: {
                            Label(isInEditMode ? "Done" : "Edit" , systemImage: isInEditMode ? "xmark" : "pencil")
                        }
                    )
                    .tint(isInEditMode ? .red : .accentColor)
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
        .onAppear(perform: viewModel.observe )
        .onReceive(Just(viewModel.recipeItems)) { recipeItems in
            withAnimation {
                self.recipeItems = recipeItems
            }
        }
        .alertCustom(viewModel.alert)
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
                        Button(
                            action: {
                                showUpdateSheet(section: section, item: item)
                            },
                            label: {
                                HStack {
                                    Text(item.itemName).foregroundStyle(.primary)
                                    Spacer()
                                    Text(item.amount.description)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .backgroundStyle(.secondary)
                                    Label("", systemImage: "chevron.up.chevron.down")
                                        .labelStyle(.iconOnly)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        )
                        .foregroundStyle(.primary)
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
                HStack {
                    Text(headerText)
                    Spacer()
                    if (isInEditMode && viewModel.recipeItems.recipeSections.count > 1) {
                        Button(
                            action: { viewModel.alert.queueRename(id: section.recipeSectionId, name: section.recipeSectionName) },
                            label: { Text("Rename Section").textCase(.none).font(.footnote) }
                        )
                    }
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        RecipeIngredientsView(.shared, recipeId: 1, recipeName: "Green Chili Mac & Cheese")
    }
}
