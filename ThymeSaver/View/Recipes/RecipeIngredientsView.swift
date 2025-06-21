import SwiftUI
import Observation
import Combine

struct RecipeIngredientsView: View {
    @Environment(\.appDatabase) var appDatabase
    
    @State private var viewModel: ViewModel
    
    @State private var recipeSections: [RecipeSect] = []
    
    @State private var isInEditMode: Bool = false
    @State private var showBottomSheet: Bool = false
    
    @State private var checked: [Int:Bool] = [:]
    
    init(_ appDatabase: AppDatabase, recipeId: Int, recipeName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase, recipeId: recipeId, recipeName: recipeName))
    }
    
    var body: some View {
        List {
            Section("Details") {
                NavigationLink(
                    destination: {
                        RecipeStepsView(
                            appDatabase,
                            recipeId: viewModel.recipeId,
                            recipeName: viewModel.recipeName)
                    },
                    label: { Text("Steps") }
                )
            }
            
            ForEach(Array(self.recipeSections.enumerated()), id: \.offset) { index, section in
                let showHeader: Bool = isInEditMode || !section.entries.isEmpty || index == 0
                sectionContents(section, sectionIndex: index, showHeader: showHeader)
            }
        }
        .navigationTitle(viewModel.recipeName).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(
                    action: {
                        viewModel.staticProperties.checked = [:]
                    },
                    label: {
                        VStack {
                            Text("Recipe Ingredients").font(.headline)
                            Text(viewModel.recipeName).font(.subheadline)
                        }
                    }
                )
                .foregroundStyle(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(
                        action: {
                            withAnimation {
                                $isInEditMode.wrappedValue = !isInEditMode
                            }
                        },
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
                    let curValidPreps = viewModel.curValidPreps
                    Section("Details") {
                        if (viewModel.showSectionPicker) {
                            Picker("Section", selection: viewModel.selectedSectionIdBinding) {
                                ForEach(self.recipeSections) { recipeSection in
                                    Text(recipeSection.recipeSectionName).tag(recipeSection.recipeSectionId)
                                }
                            }
                        }
                        
                        if (viewModel.enableItemPicker) {
                            FilterSelectionPicker(
                                "Ingredient",
                                selection: viewModel.selItemBinding,
                                options: viewModel.curValidItems
                            )
                        }
                        else {
                            HStack {
                                Text("Item")
                                Spacer()
                                Text(viewModel.selItem?.itemName ?? "(None)").foregroundStyle(.secondary)
                            }
                        }
                        
                        if (viewModel.showPrepPicker) {
                            if (viewModel.enablePrepPicker) {
                                Picker("Prep", selection: $viewModel.selPrep ) {
                                    ForEach(curValidPreps) { prep in
                                        Text(prep.prepName).tag(prep)
                                    }
                                }
                            }
                            else {
                                HStack {
                                    Text("Prep")
                                    Spacer()
                                    Text(viewModel.selPrep.prepName).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                        
                    
                    Section("Amount") {
                        AmountPicker(amount: $viewModel.selectedAmount)
                    }
                    
                    ListButton(
                        action: {
                            showBottomSheet = false
                            viewModel.addOrUpdateRecipeEntry()
                        },
                        label: {
                            Text(viewModel.isNewItemScreen ? "Add Ingredient" : "Update Ingredient")
                        }
                    )
                    .tint(viewModel.isNewItemScreen ? .blue : .indigo)
                    .disabled(!viewModel.selectedOkay)
                }
                .navigationTitle("Item Details").toolbarTitleDisplayMode(.inline)
            }
            .presentationDetents([.height(500)])
        })
        .onAppear(perform: viewModel.observe )
        .onReceive(Just(viewModel.recipeSections)) { recipeSections in
            withAnimation {
                self.recipeSections = recipeSections
            }
        }
        .onReceive(Just(viewModel.staticProperties.checked)) { checked in
            withAnimation {
                self.checked = checked
            }
        }
        .alertCustom(viewModel.alert)
    }
    
    @ViewBuilder
    func sectionContents(_ section: RecipeSect, sectionIndex: Int, showHeader: Bool = true) -> some View {
        let headerText: String = self.recipeSections.count < 2 ? "Ingredients" : section.recipeSectionName
        Section(
            content: {
                if (section.entries.isEmpty && showHeader) {
                    Text("(No Items Yet)").foregroundStyle(.secondary)
                }
                
                ForEach(section.entries) { entry in
                    if (isInEditMode) {
                        Button(
                            action: {
                                viewModel.setupUpdateItemScreen(section: section, entry: entry)
                                showBottomSheet = true
                            },
                            label: {
                                HStack {
                                    Text(entry.item.itemName).foregroundStyle(.primary)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(entry.amount.description)
                                        if (entry.prep.prepId != 0) {
                                            Text(entry.prep.prepName).font(.caption)
                                        }
                                    }
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .backgroundStyle(.secondary)
                                }
                            }
                        )
                        .foregroundStyle(.primary)
                        .transition(.slide)
                    }
                    else {
                        //let checked: Bool = ViewModel.entryChecked[entry.recipeEntryId] ?? false
                        let checked: Bool = self.checked[entry.recipeEntryId] ?? false
                        CheckboxItem(
                            isChecked: checked,
                            onToggle: {
                                withAnimation {
                                    viewModel.staticProperties.checked[entry.recipeEntryId] = !checked
                                }
                            },
                            text: entry.item.itemName,
                            subtitle: entry.amount.description,
                            subsubtitle: entry.prep.prepId != 0 ? entry.prep.prepName : nil
                        )
                        .deleteDisabled(true)
                    }
                }
                .onDelete { offsets in
                    offsets.forEach { index in
                        viewModel.deleteRecipeEntry(self.recipeSections[sectionIndex].entries[index])
                    }
                }
            },
            header: {
                if (showHeader) {
                    HStack {
                        Text(headerText)
                        Spacer()
                        if (isInEditMode && viewModel.recipeSections.count > 1) {
                            Button(
                                action: { viewModel.alert.queueRename(id: section.recipeSectionId, name: section.recipeSectionName) },
                                label: { Text("Rename Section").textCase(.none).font(.footnote) }
                            )
                        }
                    }
                }
            },
            footer: {
                if (section.recipeSectionId == viewModel.lastRecipeSectionId) {
                    if (isInEditMode) {
                        HStack {
                            Spacer()
                            Button("Add New Section") {
                                viewModel.alert.queueAdd()
                            }.font(.footnote)
                        }
                    }
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        RecipeIngredientsView(.shared, recipeId: 1, recipeName: "Pasta Alfredo")
    }
}
