//
//  MoveToFolderPicker.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/2/25.
//

import Foundation
import SwiftData
import SwiftUI

struct MoveToFolderPicker: View {
    @Environment(\.modelContext) private var modelContext
    var card: Card
    @Query var folders: [Folder]
    
    var body: some View {
        Picker("Move", selection: Binding<Folder?>(
            get: { card.folder },
            set: { newFolder in
                Task {
                    do {
                        try await card.moveToFolder(folder: newFolder)
                    } catch {
                        print("Error moving card to folder: \(error)")
                    }
                }
            }
        )) {
            // Add an option for no folder (nil)
            Text("None").tag(nil as Folder?)
            
            // List all folders
            ForEach(folders) { folder in
                Text(folder.name).tag(folder as Folder?)
            }
        }
        .pickerStyle(.menu)
    }
}
