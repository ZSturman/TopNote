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
    @EnvironmentObject var selectedCardModel: SelectedCardModel
    
    @Query var cards: [Card]
    @Query var tags: [CardTag]
    @Query var folders: [Folder]
    
    @Binding var selectedFolder: FolderSelection?
    var tagSelectionStates: [UUID: TagSelectionState]
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
    @State var isDeletedExpanded = true
    
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
        tagSelectionStates: [UUID: TagSelectionState],
        deepLinkedCardID: Binding<UUID?> = .constant(nil)
    ) {
        _selectedFolder = selectedFolder
        self.tagSelectionStates = tagSelectionStates
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
            Group {
                contentListView
            }
            .listStyle(.plain)
            .navigationTitle(selectedFolder?.name ?? "All Cards")
            .searchable(text: $searchText, prompt: "Search cards")
            .accessibilityIdentifier("CardListView")
            .onAppear(perform: handleOnAppear)
            .onChange(of: searchText) { oldValue, newValue in
                handleSearchChange(oldValue: oldValue, newValue: newValue)
            }
            .onChange(of: selectedFolder) { oldValue, newValue in
                handleFolderChange(oldValue: oldValue, newValue: newValue)
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
