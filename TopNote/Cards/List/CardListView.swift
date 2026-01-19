//  CardList.swift
//  TopNote
//
//  Created by Zachary Sturman on 7/28/25.
//

import Foundation
import SwiftData
import SwiftUI
import TipKit

struct CardListView: View {
    @Environment(\.modelContext) var context
    //@Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    
    @Query var cards: [Card]
    @Query var tags: [CardTag]
    @Query var folders: [Folder]
    
    @Binding var selectedFolder: FolderSelection?
    @Binding var tagSelectionStates: [UUID: TagSelectionState]
    @Binding var deepLinkedCardID: UUID?
    
    // Sorting & filtering
    @State var sortCriteria: CardSortCriteria = .enqueuedAt
    @State var ascending: Bool = true
    @State var filterOptions: [CardFilterOption] = CardFilterOption.allCases
    
    // UI state
    @State var showAddCardActionSheet = false
    @State var showShareSheet = false
    @State var exportedFileURL: URL?
    
    @State var isQueueExpanded = true
    @State var isUpcomingExpanded = true
    @State var isArchivedExpanded = false
    @State var isDeletedExpanded = false  // Collapsed by default
    
    // Export/Import/Share sheets
    @State var showExportImportSheet = false
    @State var showExportSheet = false
    @State var showImportSheet = false
    @State var showShareConfigSheet = false

    @State var importMode: ImportMode = .json
    @State var showImportPicker = false
    @State var selectionMode = false
    @State var selectedCards = Set<Card>()
    
    @State var showImportSuccessAlert = false
    @State var importErrorMessage: String? = nil
    
    @State var searchText = ""
    @State var scrollToCardID: UUID? = nil
    @State var priorityChangedForCardID: UUID? = nil
    @State var lastDeselectedCardID: UUID? = nil
    
    // New card sheet state
    @State var showNewCardSheet = false
    @State var newCardType: CardType = .note
    @State var showAIGeneratorFromDialog = false
    
    // Batch action sheets
    @State var showNewFolderForBatch = false
    @State var showNewTagForBatch = false
    @State var newBatchFolderName = ""
    @State var newBatchTagName = ""
    
    // Edit tags sheet (iPhone compact view)
    @State var showEditTagsSheet = false
    // Tag filter sheet (for filter menu)
    @State var showTagFilterSheet = false
    
    // MARK: - Cached Card Lists (Performance Optimization)
    // These cached lists prevent redundant filtering operations that were causing crashes
    @State var cachedFilteredCards: [Card] = []
    @State var cachedQueueCards: [Card] = []
    @State var cachedUpcomingCards: [Card] = []
    @State var cachedArchivedCards: [Card] = []
    @State var cachedDeletedCards: [Card] = []
    @State var cachedCardCounts: (todo: Int, note: Int, flashcard: Int) = (0, 0, 0)
    @State var lastCacheKey: CacheKey? = nil
    @State var pendingSectionRefreshTask: Task<Void, Never>? = nil
    @State var lastSectionHash: Int = 0  // Tracks section-affecting properties only
    
    // Cache key to detect when we need to recompute
    struct CacheKey: Equatable {
        let cardCount: Int
        let cardStateHash: Int  // Hash of card IDs and relevant state properties
        let filterOptions: [CardFilterOption]
        let selectedFolder: FolderSelection?
        let tagStates: [UUID: TagSelectionState]
        let searchText: String
    }
    
    var currentCacheKey: CacheKey {
        // Create a hash from card IDs AND relevant state properties
        // This ensures cache invalidates when cards move between sections
        let cardStateHash = cards.reduce(0) { hash, card in
            var cardHash = card.id.hashValue
            cardHash ^= card.isDeleted.hashValue
            cardHash ^= card.isArchived.hashValue
            cardHash ^= card.nextTimeInQueue.hashValue
            cardHash ^= (card.folder?.id.hashValue ?? 0)
            cardHash ^= card.cardType.hashValue
            return hash ^ cardHash
        }
        return CacheKey(
            cardCount: cards.count,
            cardStateHash: cardStateHash,
            filterOptions: filterOptions,
            selectedFolder: selectedFolder,
            tagStates: tagSelectionStates,
            searchText: searchText
        )
    }
    
    /// Hash for section-affecting properties only: isDeleted, isArchived, queue eligibility
    /// Called explicitly only when cards array changes to avoid repeated computation
    func computeSectionHash() -> Int {
        cards.reduce(0) { hash, card in
            var cardHash = card.id.hashValue
            cardHash ^= card.isDeleted.hashValue
            cardHash ^= card.isArchived.hashValue
            // Only include whether card is in queue (not exact time)
            cardHash ^= (card.nextTimeInQueue <= Date.now).hashValue
            return hash ^ cardHash
        }
    }
    
    // Tip tracking
    @State var appOpenCount = 0
    @State var hasViewedQueueCard = false
    
    let addFirstCardTip = FirstNoteTip()
    let addWidgetTip = AddWidgetTip()
    let firstQueueCardTip = FirstQueueCardTip()
    let customizeWidgetTip = CustomizeWidgetTip()
    let getStartedTip = GetStartedTip()
    let firstNoteTip = FirstNoteTip_Skip()
    let firstTodoTip = FirstTodoTip_Skip()
    let firstFlashcardTip = FirstFlashcardTip_Skip()
    
    enum ImportMode {
        case json
        case csv
    }
    
    
    private struct CardListTaskID: Equatable {
        let sortCriteria: CardSortCriteria
        let ascending: Bool
        let folderSelection: FolderSelection?
        let filterOptions: [CardFilterOption]
        let tagStates: [UUID: TagSelectionState]
    }
    
    init(
        selectedFolder: Binding<FolderSelection?>,
        tagSelectionStates: Binding<[UUID: TagSelectionState]>,
        deepLinkedCardID: Binding<UUID?> = .constant(nil)
    ) {
        _selectedFolder = selectedFolder
        _tagSelectionStates = tagSelectionStates
        _deepLinkedCardID = deepLinkedCardID
        
    }
    
    private var taskID: CardListTaskID {
        CardListTaskID(
            sortCriteria: sortCriteria,
            ascending: ascending,
            folderSelection: selectedFolder,
            filterOptions: filterOptions,
            tagStates: tagSelectionStates
        )
    }
    
    var body: some View {
        ScrollViewReader { proxy in
                    contentListView
                .listStyle(.plain)
            
            .navigationTitle(selectedFolder?.name ?? "All Cards")
           
            .searchable(text: $searchText, prompt: "Search cards")
            .accessibilityIdentifier("CardListView")
            .onAppear {
                handleOnAppear()
                lastSectionHash = computeSectionHash()
                refreshCacheIfNeeded()
            }
            .onChange(of: cards) { _, _ in
                // Check if section-affecting properties changed
                let newSectionHash = computeSectionHash()
                if lastSectionHash != newSectionHash {
                    // Section membership may have changed - use debounced refresh
                    scheduleDebouncedSectionRefresh()
                } else {
                    // Only non-section-affecting properties changed - immediate cache check
                    refreshCacheIfNeeded()
                }
            }
            .onChange(of: filterOptions) { _, _ in
                refreshCacheIfNeeded()
            }
            .onChange(of: selectedFolder) { oldValue, newValue in
                handleFolderChange(oldValue: oldValue, newValue: newValue)
                refreshCacheIfNeeded()
            }
            .onChange(of: tagSelectionStates) { _, _ in
                refreshCacheIfNeeded()
            }
            .onChange(of: searchText) { oldValue, newValue in
                handleSearchChange(oldValue: oldValue, newValue: newValue)
                refreshCacheIfNeeded()
            }
            .onChange(of: deepLinkedCardID) { oldValue, newValue in
                handleDeepLink(oldValue: oldValue, newValue: newValue)
            }
            .onChange(of: scrollToCardID) { _, newID in
                scrollToCardIDChanged(to: newID, proxy: proxy)
            }
            .onChange(of: selectedCardModel.selectedCard?.id) { oldID, newID in
                handleSelectionChange(oldID: oldID, newID: newID)
            }
            .toolbar {
                leadingToolbarItems
                trailingToolbarItems
            }
        
            .overlay(alignment: .bottomTrailing) {
                addCardButton
            }
            .sheet(isPresented: $showShareSheet) {
                if let exportedFileURL {
                    ShareSheet(activityItems: [exportedFileURL])
                }
            }
            .sheet(isPresented: $showNewCardSheet) {
                NewCardSheet(
                    cardType: newCardType,
                    currentFolder: currentFolderForNewCard,
                    currentTagIDs: currentSelectedTagIDs(),
                    onSave: { newCard in
                        handleNewCardCreated(newCard)
                    }
                )
            }
            .sheet(isPresented: $showExportImportSheet) {
                ExportImportSheet(
                    filteredCards: filteredCards,
                    allCards: cards
                )
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSheet(
                    filteredCards: filteredCards,
                    allCards: cards
                )
            }
            .sheet(isPresented: $showImportSheet) {
                ImportSheet()
            }
            .sheet(isPresented: $showShareConfigSheet) {
                ShareConfigSheet(
                    filteredCards: filteredCards,
                    allCards: cards
                )
            }
            .sheet(isPresented: $showNewFolderForBatch) {
                NewFolderSheetForCard(
                    folderName: $newBatchFolderName,
                    onSave: { newFolder in
                        batchMoveToFolder(newFolder)
                        newBatchFolderName = ""
                    }
                )
            }
            .sheet(isPresented: $showNewTagForBatch) {
                NewTagSheetForBatch(
                    tagName: $newBatchTagName,
                    onSave: { newTag in
                        batchAddTag(newTag)
                        newBatchTagName = ""
                    }
                )
            }
            .sheet(isPresented: $showEditTagsSheet) {
                EditTagsSheet()
            }
            .sheet(isPresented: $showTagFilterSheet) {
                TagFilterSheet(tags: tags, tagSelectionStates: $tagSelectionStates)
            }

            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: importMode == .csv ? [.commaSeparatedText] : [.json]
            ) { result in
                switch importMode {
                case .json:
                    handleJSONImport(result)
                case .csv:
                    handleCSVImport(result)
                }
            }
            .alert("Import Successful!", isPresented: $showImportSuccessAlert) {
                Button("OK", role: .cancel) {}
            }
            .alert(
                "Import Failed",
                isPresented: .constant(importErrorMessage != nil)
            ) {
                Button("OK", role: .cancel) { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "Unknown error")
            }
        }
    }
}
