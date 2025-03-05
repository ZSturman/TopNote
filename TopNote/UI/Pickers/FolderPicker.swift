//
//  FolderPicker.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/2/25.
//

import Foundation
import SwiftData
import SwiftUI

struct FolderPickerView: View {
    let card: Card
    var folders: [Folder]
    @Binding var selectedFolder: Folder?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Picker("Move", selection: Binding<Folder?>(
                    get: { selectedFolder },
                    set: { newFolder in
                        selectedFolder = newFolder
                        Task {
                            do {
                                try await card.moveToFolder(folder: newFolder)
                            } catch {
                                print("Error moving card to folder: \(error)")
                            }
                        }
                    }
                )) {
                    // Option for no folder
                    Text("None").tag(nil as Folder?)
                    // Options for available folders
                    ForEach(folders) { folder in
                        Text(folder.name).tag(folder as Folder?)
                    }
                }
                .pickerStyle(.inline)
            }
            .navigationTitle("Move Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
