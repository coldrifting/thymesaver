import SwiftUI
import Kingfisher
import Observation
import Combine

struct RecipeStepsView: View {
    @Environment(\.appDatabase) var appDatabase
    @Environment(\.openURL) private var openURL
    
    @State private var viewModel: ViewModel
    
    @State private var steps: [RecipeStep] = []
    
    // Workaround to hide delete icon on transition
    @State private var edit: Bool = false
    @State private var editMode: EditMode = .inactive
    
    @State private var showBottomSheet: Bool = false
    
    @State private var opacity: Double = 1.0
    
    init(_ appDatabase: AppDatabase, recipeId: Int, recipeName: String) {
        _viewModel = State(initialValue: ViewModel(appDatabase, recipeId: recipeId, recipeName: recipeName))
    }
    
    private func showUpdateSheet(_ step: RecipeStep) {
        viewModel.recipeStepId = step.recipeStepId
        viewModel.recipeStepContent.wrappedValue = step.recipeStepContent
        $showBottomSheet.wrappedValue = true
    }
    
    var body: some View {
        List {
            if (editMode.isEditing) {
                Section("Url") {
                    TextField("Recipe URL", text: viewModel.recipeUrl)
                }
            }
            
            Section {
                ForEach(steps) { step in
                    HStack {
                        if (editMode == .active) {
                            let string: String = step.recipeStepContent
                            
                            let editText = string.chop()
                            
                            Button(
                                action: { showUpdateSheet(step) },
                                label: {
                                    if (step.isImage) {
                                        RecipeStepImage(step.recipeStepContent, height: 50, width: 280)
                                    }
                                    else {
                                        Text(editText)
                                    }
                                }
                            )
                            .foregroundStyle(.primary)
                        }
                        else {
                            if (step.isImage) {
                                RecipeStepImage(step.recipeStepContent)
                            }
                            else {
                                Text(step.recipeStepContent)
                            }
                        }
                    }
                    .deleteDisabled(edit)
                }
                .onDelete { offsets in
                    offsets.forEach { index in
                        let s = steps.filter({$0.recipeStepId != steps[index].recipeStepId})
                        viewModel.deleteStep(recipeStepId: steps[index].recipeStepId)
                        for (index, recipeStep) in s.enumerated() {
                            viewModel.setStepIndex(recipeStepId: recipeStep.recipeStepId, newIndex: index)
                        }
                    }
                }
                .onMove(perform: { indices, newOffset in
                    var s = steps.map({$0})
                    s.move(fromOffsets: indices, toOffset: newOffset)
                    for (index, recipeStep) in s.enumerated() {
                        viewModel.setStepIndex(recipeStepId: recipeStep.recipeStepId, newIndex: index)
                    }
                })
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                let label = {
                    VStack {
                        Text("Recipe Steps").font(.headline)
                        Text(viewModel.recipeName).font(.subheadline)
                    }
                }
                let urlString: String = viewModel.recipe?.url ?? ""
                let urlValid: Bool = urlString.lowercased().hasPrefix("http")
                let url: URL = URL(string: urlString) ?? URL.homeDirectory
                
                if (urlValid) {
                    Button(
                        action: { openURL(url) },
                        label: label
                    )
                    .foregroundStyle(.primary)
                }
                else {
                    label()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(
                        action: {
                            edit = !edit
                            withAnimation {
                                editMode = editMode.isEditing ? .inactive : .active
                            }
                        },
                        label: {
                            Label(editMode.isEditing ? "Done" : "Edit" , systemImage: editMode.isEditing ? "xmark" : "pencil")
                        }
                    )
                    .tint(editMode.isEditing ? .red : .accentColor)
                    
                    Button(
                        action: {
                            viewModel.recipeStepId = nil
                            viewModel.recipeStepContent.wrappedValue = ""
                            $showBottomSheet.wrappedValue = true
                        },
                        label: { Label("Add", systemImage: "plus") }
                    )
                }
            }
        }
        .sheet(
            isPresented: $showBottomSheet,
            content: {
                List {
                    Section("Recipe Step Details or Image URL") {
                        TextField("Step Details or Image URL", text: viewModel.recipeStepContent, axis: .vertical).lineLimit(12, reservesSpace: true)
                    }
                    
                    VStack {
                        Button(
                            action: {
                                $showBottomSheet.wrappedValue = false
                                viewModel.addOrUpdateStep()
                            },
                            label: { Text(viewModel.recipeStepId != nil ? "Update Recipe Step" : "Add Recipe Step")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, minHeight: 32)
                            }
                        )
                        .buttonStyle(.borderedProminent)
                        .tint(viewModel.recipeStepId != nil ? .blue : .green.mix(with: .blue, by: 0.15).mix(with: .black, by: 0.15))
                        .disabled(!viewModel.selectedOkay)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(EmptyView())
                    .listRowInsets(EdgeInsets())
                }
                .presentationDetents([.height(450)])
            }
        )
        .environment(\.editMode, $editMode)
        .navigationTitle("Recipe Steps").navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.observe)
        .onReceive(Just(viewModel.steps)) { steps in
            withAnimation {
                self.steps = steps
            }
        }
    }
    
    @ViewBuilder
    private func RecipeStepImage(_ imageUrl: String, height: CGFloat = 250, width: CGFloat = 330) -> some View {
        HStack {
            Spacer()
            KFImage(URL(string: imageUrl))
                .onProgress { receivedSize, totalSize in  }
                .onSuccess { result in  }
                .onFailure { error in
                    print(error)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipShape(.rect(cornerRadius: 10))
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        RecipeStepsView(.shared, recipeId: 1, recipeName: "Pasta Alfredo")
    }
}
