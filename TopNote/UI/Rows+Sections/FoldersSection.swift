//
//  FoldersSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/1/25.
//

import Foundation
import SwiftUI
import SwiftData

struct FoldersSection: View {
    @Environment(\.modelContext) private var modelContext
    var folders: [Folder]
    @Binding var selectedFolder: FolderSelection
    
    var body: some View {
        Section(header: Text("Folders")) {
            NavigationLink(value: FolderSelection.allCards) {
                Text(FolderSelection.allCards.name)
            }
            ForEach(folders.sorted { $0.name < $1.name }) { folder in
                NavigationLink(value: FolderSelection.folder(folder)) {
                    Text(folder.name)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(folder)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                }
            }
        }
    }
}
