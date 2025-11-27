//
//  ExistingFoldersView.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/6/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - UpdateCardFolderView
struct UpdateCardFolderView: View {
    var card: Card
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query var folders: [Folder]
    @State private var newFolderName: String = ""

    var trimmedFolderName: String {
        newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var folderExists: Bool {
        folders.contains(where: { $0.name.caseInsensitiveCompare(trimmedFolderName) == .orderedSame })
    }

    func addFolder() {
        guard !trimmedFolderName.isEmpty, !folderExists else { return }
        let newFolder = Folder(name: trimmedFolderName)
        context.insert(newFolder)
        card.folder = newFolder
        do { try context.save() } catch { /* Handle error if needed */ }
        newFolderName = ""
        dismiss()
    }

    var body: some View {
        NavigationStack {
            VStack {
                
                
                HStack {
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Spacer()
                    Button("Add") {
                        addFolder()
                    }
                    .disabled(trimmedFolderName.isEmpty || folderExists)
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
                if folderExists {
                    Text("Folder '\(trimmedFolderName)' already exists.")
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
              
            }

            List {
      

                

                Section {
                    // No Folder option
                    Button(action: {
                        card.folder = nil
                        do { try context.save() } catch { }
                        dismiss()
                    }) {
                        HStack {
                            Text("No Folder")
                            if card.folder == nil {
                                Spacer()
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }

                    // Existing folders sorted alphabetically (case insensitive)
                    ForEach(folders.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })) { folder in
                        Button(action: {
                            card.folder = folder
                            do { try context.save() } catch { }
                            dismiss()
                        }) {
                            HStack {
                                Text(folder.name)
                                if card.folder == folder {
                                    Spacer()
                                    Image(systemName: "checkmark").foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Move Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
