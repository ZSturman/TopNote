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
                // Select All always visible
                Button(allCardsSelected ? "Deselect All" : "Select All") {
                    if allCardsSelected {
                        deselectAllCards()
                    } else {
                        selectAllCards()
                    }
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
                // Cancel button in edit mode
                Button("Cancel", role: .cancel) {
                    selectionMode = false
                    selectedCards.removeAll()
                }
                
                // Batch actions menu - icon only
                Menu {
                    let noneSelected = selectedCards.isEmpty
                    
                    // Move to folder (with New Folder option)
                    Menu {
                        Button {
                            showNewFolderForBatch = true
                        } label: {
                            Label("New Folder...", systemImage: "folder.badge.plus")
                        }
                        Divider()
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
                    .disabled(noneSelected)
                    
                    // Add tags (with New Tag option)
                    Menu {
                        Button {
                            showNewTagForBatch = true
                        } label: {
                            Label("New Tag...", systemImage: "tag.fill")
                        }
                        Divider()
                        ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                            Button(tag.name) {
                                batchAddTag(tag)
                            }
                        }
                    } label: {
                        Label("Add Tag", systemImage: "tag")
                    }
                    .disabled(noneSelected)
                    
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
                    .disabled(noneSelected)
                    
                    // Repeat Interval
                    Menu {
                        ForEach(RepeatInterval.allCases.filter { $0.hours != nil }, id: \.self) { interval in
                            Button(interval.rawValue) {
                                batchSetRepeatInterval(interval)
                            }
                        }
                    } label: {
                        Label("Set Interval", systemImage: "calendar")
                    }
                    .disabled(noneSelected)
                    
                    // Policies submenu
                    Menu {
                        // Skip policy
                        Menu {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Button(policy.rawValue) {
                                    batchSetSkipPolicy(policy)
                                }
                            }
                        } label: {
                            Label("On Skip", systemImage: "forward")
                        }
                        
                        // Rating policies (only if flashcards selected)
                        let hasFlashcards = selectedCards.contains { $0.cardType == .flashcard }
                        
                        Menu {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Button(policy.rawValue) {
                                    batchSetEasyPolicy(policy)
                                }
                            }
                        } label: {
                            Label("On Easy", systemImage: "hand.thumbsup")
                        }
                        .disabled(!hasFlashcards)
                        
                        Menu {
                            ForEach(RepeatPolicy.allCases, id: \.self) { policy in
                                Button(policy.rawValue) {
                                    batchSetHardPolicy(policy)
                                }
                            }
                        } label: {
                            Label("On Hard", systemImage: "hand.thumbsdown")
                        }
                        .disabled(!hasFlashcards)
                        
                        Divider()
                        
                        // Reset on complete (only if todos selected)
                        let hasTodos = selectedCards.contains { $0.cardType == .todo }
                        
                        Button {
                            batchSetResetOnComplete(true)
                        } label: {
                            Label("Reset Interval On Complete: On", systemImage: "checkmark.circle")
                        }
                        .disabled(!hasTodos)
                        
                        Button {
                            batchSetResetOnComplete(false)
                        } label: {
                            Label("Reset Interval On Complete: Off", systemImage: "xmark.circle")
                        }
                        .disabled(!hasTodos)
                    } label: {
                        Label("Policies", systemImage: "slider.horizontal.3")
                    }
                    .disabled(noneSelected)
                    
                    Divider()
                    
                    // Status actions
                    let allDeleted = !selectedCards.isEmpty && selectedCards.allSatisfy { $0.isDeleted }
                    let someDeleted = selectedCards.contains { $0.isDeleted }
                    
                    Button {
                        batchEnqueue()
                    } label: {
                        Label("Add to Queue", systemImage: "clock")
                    }
                    .disabled(noneSelected)
                    
                    Button {
                        batchArchive()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .disabled(noneSelected)
                    
                    if allDeleted {
                        // All selected cards are deleted - show permanent delete
                        Button(role: .destructive) {
                            batchPermanentlyDelete()
                        } label: {
                            Label("Permanently Delete", systemImage: "trash.fill")
                        }
                        .disabled(noneSelected)
                    } else {
                        // Mixed or no deleted cards - show regular delete
                        Button(role: .destructive) {
                            batchSoftDelete()
                        } label: {
                            Label(someDeleted ? "Delete (skip already deleted)" : "Delete", systemImage: "trash")
                        }
                        .disabled(noneSelected)
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
                    .disabled(selectedCards.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Actions")
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
                                    Label(opt.localizedName, systemImage: opt.systemImage)
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
                                Toggle(isOn: Binding(
                                    get: { filterOptions.contains(option) },
                                    set: { isOn in
                                        if isOn {
                                            if !filterOptions.contains(option) {
                                                filterOptions.append(option)
                                            }
                                        } else {
                                            filterOptions.removeAll { $0 == option }
                                        }
                                    }
                                )) {
                                    Label(option.localizedName, systemImage: option.systemImage)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Tags option - opens tag filter sheet
                        Button {
                            showTagFilterSheet = true
                        } label: {
                            Label("Tags", systemImage: "tag")
                        }
                        
                        Divider()
                        
                        // Status filters
                        Section {
                            ForEach([CardFilterOption.enqueue, .upcoming, .archived, .deleted], id: \.self) { option in
                                Toggle(isOn: Binding(
                                    get: { filterOptions.contains(option) },
                                    set: { isOn in
                                        if isOn {
                                            if !filterOptions.contains(option) {
                                                filterOptions.append(option)
                                            }
                                        } else {
                                            filterOptions.removeAll { $0 == option }
                                        }
                                    }
                                )) {
                                    Label(option.localizedName, systemImage: option.systemImage)
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
                _ = (try? context.fetch(fetchDescriptor).count) ?? 0
             
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
