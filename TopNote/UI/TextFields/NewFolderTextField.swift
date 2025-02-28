//
//  NewFolderForm.swift
//  TopNote
//
//  Created by Zachary Sturman on 2/23/25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

struct NewFolderForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFolder: FolderSelection?
    @Query private var existingFolders: [Folder]
    
    @State private var newFolderName: String = ""
    @FocusState private var isTextFieldFocused: Bool  // Add focus state
    
    private var isFolderNameValid: Bool {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && !existingFolders.contains { $0.name == trimmedName }
    }
    
    var body: some View {
        Form {
            Section(header: Text("New Folder")) {
                TextField("Folder name", text: $newFolderName)
                    .focused($isTextFieldFocused)  // Bind focus state
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Button("Done") {
                    addFolder()
                    dismiss()
                }
                .disabled(!isFolderNameValid)
            }
            .padding()
        }
        .onAppear {
            isTextFieldFocused = true  // Focus text field when view appears
        }
    }
    
    private func addFolder() {
        let newFolder = Folder(name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(newFolder)
        selectedFolder = .folder(newFolder)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
