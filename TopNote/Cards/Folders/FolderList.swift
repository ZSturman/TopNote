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
    
    // Use lightweight count queries instead of loading all cards
    @State private var queuedCount: Int = 0
    @State private var upcomingCount: Int = 0
    @State private var archivedCount: Int = 0
    
    @Binding var selectedFolder: FolderSelection?
    @Binding  var tagSelectionStates: [UUID: TagSelectionState]
    @State private var showNewFolderInput: Bool = false
    @State private var showManageFolders: Bool = false
    
    public var body: some View {
        List(selection: $selectedFolder) {
            Section(header: Text("Folders")) {
                NavigationLink(value: FolderSelection.allCards) {
                    HStack {
                        Text(FolderSelection.allCards.name)
                        Spacer()
                        HStack(spacing: 8) {
                            Text(queuedCount == 0 ? "-" : "\(queuedCount)").bold().foregroundColor(.primary)
                            Text(upcomingCount == 0 ? "-" : "\(upcomingCount)").foregroundColor(.primary)
                            Text(archivedCount == 0 ? "-" : "\(archivedCount)").foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityIdentifier("AllCardsFolder")
                ForEach(folders.sorted { $0.name < $1.name }) { folder in
                    FolderRowView(folder: folder)
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
        .task {
            await refreshCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave).receive(on: DispatchQueue.main)) { _ in
            // Ensure we're on main thread before triggering state updates
            Task { @MainActor in
                await refreshCounts()
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
                    .accessibilityIdentifier("NewFolderButton")
                    Spacer()
                    
                    Button {
                        showManageFolders.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                            Text("Manage")
                        }
                    }
                    .accessibilityIdentifier("ManageFoldersButton")
                }
            
        }
        .sheet(isPresented: $showNewFolderInput) {
            NewFolderForm(selectedFolder: $selectedFolder)
        }
        .sheet(isPresented: $showManageFolders) {
            ManageFoldersView()
        }

    }
    
    // Fetch counts using lightweight queries that don't load full objects
    @MainActor
    private func refreshCounts() async {
        let now = Date()
        
        // Use FetchDescriptor with predicates to count without loading all data
        // Archived count
        let archivedDescriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.isArchived == true })
        archivedCount = (try? modelContext.fetchCount(archivedDescriptor)) ?? 0
        
        // Queued count - cards that are not archived and nextTimeInQueue <= now
        let queuedDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
            card.isArchived == false && card.nextTimeInQueue <= now
        })
        queuedCount = (try? modelContext.fetchCount(queuedDescriptor)) ?? 0
        
        // Upcoming count - cards that are not archived and nextTimeInQueue > now
        let upcomingDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
            card.isArchived == false && card.nextTimeInQueue > now
        })
        upcomingCount = (try? modelContext.fetchCount(upcomingDescriptor)) ?? 0
    }
}

// Helper view for folder rows with efficient single-pass counting
private struct FolderRowView: View {
    let folder: Folder
    
    private var folderCounts: (queued: Int, upcoming: Int, archived: Int) {
        let now = Date()
        var queued = 0
        var upcoming = 0
        var archived = 0
        
        for card in folder.unwrappedCards {
            if card.isArchived {
                archived += 1
            } else if card.isEnqueue(currentDate: now) {
                queued += 1
            } else {
                upcoming += 1
            }
        }
        return (queued, upcoming, archived)
    }
    
    var body: some View {
        let counts = folderCounts
        NavigationLink(value: FolderSelection.folder(folder)) {
            HStack {
                Text(folder.name)
                Spacer()
                HStack(spacing: 8) {
                    Text(counts.queued == 0 ? "-" : "\(counts.queued)").bold().foregroundColor(.primary)
                    Text(counts.upcoming == 0 ? "-" : "\(counts.upcoming)").foregroundColor(.primary)
                    Text(counts.archived == 0 ? "-" : "\(counts.archived)").foregroundColor(.secondary)
                }
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("Folder-\(folder.id.uuidString)")
    }
}

