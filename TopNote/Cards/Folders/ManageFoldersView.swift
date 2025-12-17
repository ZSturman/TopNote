//
//  ManageFoldersView.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/15/25.
//

import Foundation
import SwiftUI
import SwiftData

struct ManageFoldersView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var folders: [Folder]
    
    @State private var selectedFolders: Set<Folder> = []
    @State private var showMergeConfirmation = false
    @State private var targetFolder: Folder?
    @State private var showRenameSheet = false
    @State private var folderToRename: Folder?
    
    var sortedFolders: [Folder] {
        folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    var canMerge: Bool {
        selectedFolders.count >= 2
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if selectedFolders.isEmpty {
                    Text("Select folders to merge or manage")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    HStack {
                        Text("\(selectedFolders.count) folder(s) selected")
                            .foregroundColor(.secondary)
                        Spacer()
                        if canMerge {
                            Button("Merge") {
                                showMergeConfirmation = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                List {
                    ForEach(sortedFolders) { folder in
                        HStack {
                            Button {
                                toggleSelection(folder)
                            } label: {
                                HStack {
                                    Image(systemName: selectedFolders.contains(folder) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedFolders.contains(folder) ? .accentColor : .gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(folder.name)
                                            .foregroundColor(.primary)
                                        Text("\(folder.unwrappedCards.count) card(s)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Button {
                                folderToRename = folder
                                showRenameSheet = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                    }
                }
            }
            .navigationTitle("Manage Folders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if !selectedFolders.isEmpty {
                        Button("Clear") {
                            selectedFolders.removeAll()
                        }
                    }
                }
            }
            .confirmationDialog(
                "Merge Folders",
                isPresented: $showMergeConfirmation,
                titleVisibility: .visible
            ) {
                ForEach(Array(selectedFolders).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                    Button("Merge into '\(folder.name)'") {
                        targetFolder = folder
                        mergeFolders(into: folder)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Select which folder to keep. All cards from other selected folders will be moved into it, and the empty folders will be deleted.")
            }
            .sheet(item: $folderToRename) { folder in
                RenameFolderSheet(folder: folder)
            }
        }
    }
    
    private func toggleSelection(_ folder: Folder) {
        if selectedFolders.contains(folder) {
            selectedFolders.remove(folder)
        } else {
            selectedFolders.insert(folder)
        }
    }
    
    private func mergeFolders(into targetFolder: Folder) {
        let foldersToMerge = selectedFolders.filter { $0.id != targetFolder.id }
        
        // Move all cards from other folders to target folder
        for folder in foldersToMerge {
            for card in folder.unwrappedCards {
                card.folder = targetFolder
            }
            
            // Delete the empty folder
            context.delete(folder)
        }
        
        do {
            try context.save()
            selectedFolders.removeAll()
        } catch {
            print("Failed to merge folders: \(error)")
        }
    }
}

struct RenameFolderSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allFolders: [Folder]
    
    let folder: Folder
    @State private var newName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(folder: Folder) {
        self.folder = folder
        _newName = State(initialValue: folder.name)
    }
    
    private var isFolderNameValid: Bool {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Valid if not empty and either same as current name or doesn't conflict with others
        if trimmedName.isEmpty {
            return false
        }
        if trimmedName.caseInsensitiveCompare(folder.name) == .orderedSame {
            return true
        }
        return !allFolders.contains { $0.id != folder.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rename Folder")) {
                    TextField("Folder name", text: $newName)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isFolderNameValid {
                                saveRename()
                            }
                        }
                    
                    if !isFolderNameValid {
                        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedName.isEmpty {
                            Text("Please enter a folder name.")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else if allFolders.contains(where: { $0.id != folder.id && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
                            Text("A folder with this name already exists.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveRename()
                    }
                    .disabled(!isFolderNameValid)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func saveRename() {
        folder.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try context.save()
            dismiss()
        } catch {
            print("Failed to rename folder: \(error)")
        }
    }
}
