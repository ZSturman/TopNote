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
    @FocusState private var isTextFieldFocused: Bool
    
    private var trimmedName: String {
        newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isFolderNameValid: Bool {
        !trimmedName.isEmpty && !existingFolders.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    
    private var errorMessage: String? {
        if trimmedName.isEmpty {
            return nil
        }
        if existingFolders.contains(where: { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            return "A folder with this name already exists"
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Folder name", text: $newFolderName)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isFolderNameValid {
                                addFolder()
                            }
                        }
                } header: {
                    Text("Name")
                } footer: {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                if !existingFolders.isEmpty {
                    Section {
                        ForEach(existingFolders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.secondary)
                                Text(folder.name)
                                Spacer()
                                Text("\(folder.unwrappedCards.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Existing Folders")
                    }
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        addFolder()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFolderNameValid)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func addFolder() {
        let newFolder = Folder(name: trimmedName)
        modelContext.insert(newFolder)
        selectedFolder = .folder(newFolder)
        Card.throttledWidgetReload()
        dismiss()
    }
}
