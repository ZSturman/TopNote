//
//  FolderList.swift
//  TopNote
//
//  Created by Zachary Sturman on 7/28/25.
//

import Foundation
import SwiftUI 
import SwiftData

public struct FolderList: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query var folders: [Folder]
    @Query var tags: [CardTag]
    @Query var allCards: [Card]
    
    @Binding var selectedFolder: FolderSelection?
    @Binding  var tagSelectionStates: [UUID: TagSelectionState]
    @State private var showNewFolderInput: Bool = false
    
    
    public var body: some View {
        List(selection: $selectedFolder) {
            Section(header: Text("Folders")) {
                NavigationLink(value: FolderSelection.allCards) {
                    HStack {
                        Text(FolderSelection.allCards.name)
                        Spacer()
                        let queued = allCards.filter { !$0.isArchived && $0.isEnqueue(currentDate: Date()) }.count
                        let upcoming = allCards.filter { !$0.isArchived && !$0.isEnqueue(currentDate: Date()) }.count
                        let archived = allCards.filter { $0.isArchived }.count
                        HStack(spacing: 8) {
                            Text(queued == 0 ? "-" : "\(queued)").bold().foregroundColor(.primary)
                            Text(upcoming == 0 ? "-" : "\(upcoming)").foregroundColor(.primary)
                            Text(archived == 0 ? "-" : "\(archived)").foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(folders.sorted { $0.name < $1.name }) { folder in
                    NavigationLink(value: FolderSelection.folder(folder)) {
                        HStack {
                            Text(folder.name)
                            Spacer()
                            let queued = folder.unwrappedCards.filter { !$0.isArchived && $0.isEnqueue(currentDate: Date()) }.count
                            let upcoming = folder.unwrappedCards.filter { !$0.isArchived && !$0.isEnqueue(currentDate: Date()) }.count
                            let archived = folder.unwrappedCards.filter { $0.isArchived }.count
                            HStack(spacing: 8) {
                                Text(queued == 0 ? "-" : "\(queued)").bold().foregroundColor(.primary)
                                Text(upcoming == 0 ? "-" : "\(upcoming)").foregroundColor(.primary)
                                Text(archived == 0 ? "-" : "\(archived)").foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            DispatchQueue.main.async {
                                modelContext.delete(folder)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                    }
                }
            }
            if tags.count > 0 {
                TagsSection(tags: tags, tagSelectionStates: $tagSelectionStates)
            }

        }
        .toolbar {
        
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showNewFolderInput.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("New Folder")
                        }
                    }
                    Spacer()
                }
            
        }
        .sheet(isPresented: $showNewFolderInput) {
            NewFolderForm(selectedFolder: $selectedFolder)
        }

    }
}

