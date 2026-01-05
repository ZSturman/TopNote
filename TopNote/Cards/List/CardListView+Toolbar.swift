//
//  CardListView+Toolbar.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

extension CardListView {
    @ToolbarContentBuilder
    var leadingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if selectionMode {
                Button(allCardsSelected ? "Deselect All" : "Select All") {
                    if allCardsSelected {
                        deselectAllCards()
                    } else {
                        selectAllCards()
                    }
                }
                Button("Cancel", role: .cancel) {
                    selectionMode = false
                    selectedCards.removeAll()
                }
            } else if selectedCardModel.selectedCard != nil {
                // When a single card is selected, show Cancel on the leading side
                Button("Cancel", role: .cancel) {
                    cancelEdits()
                }
            }
        }
    }

    @ToolbarContentBuilder
    var trailingToolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if selectionMode {
                // Batch actions menu when cards are selected
                Menu {
                    // Move to folder
                    Menu {
                        Button("No Folder") {
                            batchMoveToFolder(nil)
                        }
                        Divider()
                        ForEach(folders.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { folder in
                            Button(folder.name) {
                                batchMoveToFolder(folder)
                            }
                        }
                    } label: {
                        Label("Move to Folder", systemImage: "folder")
                    }
                    
                    // Add tags
                    Menu {
                        ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                            Button(tag.name) {
                                batchAddTag(tag)
                            }
                        }
                    } label: {
                        Label("Add Tag", systemImage: "tag")
                    }
                    
                    Divider()
                    
                    // Priority
                    Menu {
                        ForEach(PriorityType.allCases, id: \.self) { priority in
                            Button {
                                batchSetPriority(priority)
                            } label: {
                                Label(priority.displayName, systemImage: priority.iconName)
                            }
                        }
                    } label: {
                        Label("Set Priority", systemImage: "flag")
                    }
                    
                    Divider()
                    
                    // Status actions
                    Button {
                        batchEnqueue()
                    } label: {
                        Label("Add to Queue", systemImage: "clock")
                    }
                    
                    Button {
                        batchArchive()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    
                    Button(role: .destructive) {
                        batchSoftDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Divider()
                    
                    // Export submenu
                    Menu {
                        Button("as JSON") {
                            exportCardsAsJSON(Array(selectedCards))
                            exitSelectionMode()
                        }
                        Button("as CSV") {
                            exportCardsAsCSV(Array(selectedCards))
                            exitSelectionMode()
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Text("Actions")
                }
                .disabled(selectedCards.isEmpty)
            } else if selectedCardModel.selectedCard != nil {
                // Only show Done when a card is selected; hide sort/filter/settings
                Button("Done") {
                    finishEdits()
                }
            } else {
                // Share/Export/Import menu with submenus
                Menu {
                    // Share submenu
                    Button {
                        showShareConfigSheet = true
                    } label: {
                        Label("Share...", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    // Export submenu
                    Menu {
                        Button {
                            showExportSheet = true
                        } label: {
                            Label("Export Cards...", systemImage: "square.and.arrow.up.on.square")
                        }
                    } label: {
                        Label("Export", systemImage: "arrow.up.doc")
                    }
                    
                    // Import submenu
                    Menu {
                        Button {
                            showImportSheet = true
                        } label: {
                            Label("Import Cards...", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Import", systemImage: "arrow.down.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Share, Export & Import")
                
                // Combined Sort & Filter menu
                Menu {
                    // Sort submenu
                    Menu {
                        ForEach(CardSortCriteria.allCases) { opt in
                            Button {
                                sortCriteria = opt
                            } label: {
                                if sortCriteria == opt {
                                    Label(opt.localizedName, systemImage: "checkmark")
                                } else {
                                    Text(opt.localizedName)
                                }
                            }
                        }
                        Divider()
                        Button {
                            ascending.toggle()
                        } label: {
                            Label(ascending ? "Ascending" : "Descending", systemImage: ascending ? "arrow.up" : "arrow.down")
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    
                    // Filter submenu (inline for quick access)
                    Menu {
                        // Type filters
                        Section {
                            ForEach([CardFilterOption.todo, .flashcard, .note], id: \.self) { option in
                                Button {
                                    toggleFilterOption(option)
                                } label: {
                                    if filterOptions.contains(option) {
                                        Label(option.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(option.rawValue)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Status filters
                        Section {
                            ForEach([CardFilterOption.enqueue, .upcoming, .archived, .deleted], id: \.self) { option in
                                Button {
                                    toggleFilterOption(option)
                                } label: {
                                    if filterOptions.contains(option) {
                                        Label(option.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(option.rawValue)
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                } label: {
                    Label("Sort & Filter", systemImage: "arrow.up.arrow.down.circle")
                }
                .menuActionDismissBehavior(.disabled)
                .accessibilityIdentifier("SortAndFilter")
                
                // Edit mode toggle (renamed from checkmark.circle)
                Button {
                    selectionMode = true
                } label: {
                    Text("Edit")
                }
                .accessibilityLabel("Edit Cards")
            }
        }
    }

    func finishEdits() {
        // Commit changes; if card is empty, delete it
        if let card = selectedCardModel.selectedCard {

            // Apply any cached drafts so we don't rely on per-keystroke model mutations
            if let draftContent = selectedCardModel.draftContent {
                card.content = draftContent
            }
            if card.cardType == .flashcard, let draftAnswer = selectedCardModel.draftAnswer {
                card.answer = draftAnswer
            }
            
            let contentIsEmpty = card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let shouldDelete = contentIsEmpty
            
            
            if shouldDelete {
            
                context.delete(card)
            }
            
            do {
                try context.save()
                
                // DEBUG: Print card count after save
                let fetchDescriptor = FetchDescriptor<Card>()
                let count = (try? context.fetch(fetchDescriptor).count) ?? 0
             
            } catch {
                print("📝 [FINISH EDITS] ERROR saving context: \(error)")
            }
        }
        selectedCardModel.clearDrafts()
        selectedCardModel.clearSelection()
    }

    func cancelEdits() {
        if let card = selectedCardModel.selectedCard {
            
            if selectedCardModel.isNewlyCreated {
                context.delete(card)
                try? context.save()
            } else {
                selectedCardModel.restoreSnapshotIfAvailable()
                try? context.save()
            }
        }
        selectedCardModel.clearDrafts()
        selectedCardModel.clearSelection()
    }
    
    func toggleFilterOption(_ option: CardFilterOption) {
        if filterOptions.contains(option) {
            filterOptions.removeAll { $0 == option }
        } else {
            filterOptions.append(option)
        }
    }
}
