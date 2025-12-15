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
                Menu("Export") {
                    Button("as JSON") {
                        exportCardsAsJSON(Array(selectedCards))
                        selectionMode = false
                        selectedCards.removeAll()
                    }
                    Button("as CSV") {
                        exportCardsAsCSV(Array(selectedCards))
                        selectionMode = false
                        selectedCards.removeAll()
                    }
                }
                .disabled(selectedCards.isEmpty)
            } else if selectedCardModel.selectedCard != nil {
                // Only show Done when a card is selected; hide sort/filter/settings
                Button("Done") {
                    finishEdits()
                }
            } else {
                Menu {
                    Menu("Export Filtered Cards") {
                        Button("as JSON") {
                            exportCardsAsJSON(filteredCards)
                        }
                        Button("as CSV") {
                            exportCardsAsCSV(filteredCards)
                        }
                    }
                    Menu("Import Cards") {
                        Button("from JSON") {
                           
                            importMode = .json
                            showImportPicker = true
                        }
                        Button("from CSV") {
                            importMode = .csv
                            showImportPicker = true
                        }
                    }
                } label: {
                    Image(systemName: "gear")
                }
                //.popoverTip(importExportTip, arrowEdge: .bottom)
                Menu {
                    ForEach(CardSortCriteria.allCases) { opt in
                        Button(opt.localizedName) { sortCriteria = opt }
                    }
                    Divider()
                    Button(ascending ? "Ascending" : "Descending") {
                        ascending.toggle()
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .menuActionDismissBehavior(.disabled)
                .accessibilityIdentifier("Sort")
                // Show filter menu only for enqueuedAt and createdAt
                if sortCriteria == .enqueuedAt || sortCriteria == .createdAt {
                    CardFilterMenu(selectedOptions: $filterOptions)
                }
            }
        }
    }

    func finishEdits() {
        // Commit changes; if card is empty, delete it
        if let card = selectedCardModel.selectedCard {
            print("📝 [FINISH EDITS] Card ID: \(card.id)")
            print("📝 [FINISH EDITS] Card content: '\(card.content)'")

            // Apply any cached drafts so we don't rely on per-keystroke model mutations
            if let draftContent = selectedCardModel.draftContent {
                card.content = draftContent
            }
            if card.cardType == .flashcard, let draftAnswer = selectedCardModel.draftAnswer {
                card.answer = draftAnswer
            }
            
            let contentIsEmpty = card.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let hasNoImage = card.contentImageData == nil
            let shouldDelete = contentIsEmpty && hasNoImage
            
            print("📝 [FINISH EDITS] Content isEmpty: \(contentIsEmpty), hasNoImage: \(hasNoImage)")
            
            if shouldDelete {
                print("📝 [FINISH EDITS] DELETING card because content is empty AND no image")
                context.delete(card)
            } else {
                print("📝 [FINISH EDITS] KEEPING card (has content or image)")
            }
            
            do {
                try context.save()
                print("📝 [FINISH EDITS] Context saved successfully")
                
                // DEBUG: Print card count after save
                let fetchDescriptor = FetchDescriptor<Card>()
                let count = (try? context.fetch(fetchDescriptor).count) ?? 0
                print("📝 [FINISH EDITS] Card count after save: \(count)")
            } catch {
                print("📝 [FINISH EDITS] ERROR saving context: \(error)")
            }
        }
        selectedCardModel.clearDrafts()
        selectedCardModel.clearSelection()
    }

    func cancelEdits() {
        if let card = selectedCardModel.selectedCard {
            print("📝 [CANCEL EDITS] Card ID: \(card.id), isNewlyCreated: \(selectedCardModel.isNewlyCreated)")
            
            if selectedCardModel.isNewlyCreated {
                // New card -> delete entirely
                print("📝 [CANCEL EDITS] DELETING newly created card")
                context.delete(card)
                try? context.save()
            } else {
                // Existing card -> restore snapshot
                print("📝 [CANCEL EDITS] Restoring snapshot for existing card")
                selectedCardModel.restoreSnapshotIfAvailable()
                try? context.save()
            }
        }
        selectedCardModel.clearDrafts()
        selectedCardModel.clearSelection()
    }
}
