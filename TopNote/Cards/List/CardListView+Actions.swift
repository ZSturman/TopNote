//
//  CardListView+Actions.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

extension CardListView {
    
    // MARK: - Computed Properties for New Card Sheet
    
    var currentFolderForNewCard: Folder? {
        guard let sel = selectedFolder else { return nil }
        if case .folder(let f) = sel { return f }
        return nil
    }
    
    // MARK: - New Card Sheet Flow
    
    func presentNewCardSheet(ofType type: CardType) {
        newCardType = type
        showNewCardSheet = true
    }
    
    func handleNewCardCreated(_ newCard: Card) {
        let wasEmptyBeforeInsert = cards.count <= 1 // Card was just inserted
        
        // Ensure Upcoming filter is enabled
        if !filterOptions.contains(.upcoming) {
            filterOptions.append(.upcoming)
        }
        
        // Ensure the new card's type is visible in filters
        let cardTypeFilter: CardFilterOption
        switch newCard.cardType {
        case .todo: cardTypeFilter = .todo
        case .flashcard: cardTypeFilter = .flashcard
        case .note: cardTypeFilter = .note
        }
        if !filterOptions.contains(cardTypeFilter) {
            filterOptions.append(cardTypeFilter)
        }
        
        // Expand Upcoming section
        isUpcomingExpanded = true
        
        // Donate tips
        if wasEmptyBeforeInsert {
            Task {
                await AddWidgetTip.createdFirstCardEvent.donate()
                await GetStartedTip.userTookActionEvent.donate()
            }
        } else {
            Task {
                await GetStartedTip.userTookActionEvent.donate()
            }
        }
        
        // Donate to card-type-specific events
        Task {
            switch newCard.cardType {
            case .note:
                await FirstNoteTip_Skip.createdFirstNoteEvent.donate()
            case .todo:
                await FirstTodoTip_Skip.createdFirstTodoEvent.donate()
            case .flashcard:
                await FirstFlashcardTip_Skip.createdFirstFlashcardEvent.donate()
            }
        }
        
        // Scroll to the new card after a brief delay to ensure it's rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            scrollToCardID = newCard.id
        }
    }
    
    // MARK: - Legacy addCard (kept for reference, now uses sheet)
    
    func addCard(ofType type: CardType) {
        // Now just presents the sheet instead of inline creation
        presentNewCardSheet(ofType: type)
    }
    
    func delete(cards sectionCards: [Card], at offsets: IndexSet) {
        let toDelete = offsets.map { sectionCards[$0] }
        toDelete.forEach { card in
            context.delete(card)
        }
        do {
            try context.save()
            
            // DEBUG: Print card count after delete
            let fetchDescriptor = FetchDescriptor<Card>()
            let count = (try? context.fetch(fetchDescriptor).count) ?? 0
        } catch {
            print("📝 [DELETE] ERROR saving context: \(error)")
        }
        // After deleting cards, clean up orphan tags
        do {
            let fetchDescriptor = FetchDescriptor<CardTag>()
            let allTags = try context.fetch(fetchDescriptor)
            let orphanTags = allTags.filter { $0.unwrappedCards.isEmpty }
            orphanTags.forEach { context.delete($0) }
            if !orphanTags.isEmpty {
                try context.save()
            }
        } catch {
            // Optionally handle error if desired
            print("📝 [DELETE] Failed to delete orphaned tags: \(error)")
        }
        // If the deleted card was selected, clear selection and snapshot
        if let selectedCard = selectedCardModel.selectedCard,
           toDelete.contains(where: { $0.id == selectedCard.id })
        {
            selectedCardModel.clearSelection()
        }
    }
    func select(_ card: Card) {
        if selectedCardModel.selectedCard?.id == card.id {
            // Deselecting by tapping selected card: treat as Done behavior
            finishEdits()
        } else {
            selectedCardModel.selectedCard = card
            selectedCardModel.setIsNewlyCreated(false)
            selectedCardModel.captureSnapshot()
        }
    }
    
    func handleSearchChange(oldValue: String, newValue: String) {                 if !newValue.isEmpty && selectedCardModel.selectedCard != nil {
        selectedCardModel.clearSelection()
    }}
    func handleFolderChange(oldValue: FolderSelection?, newValue: FolderSelection?) {
        if oldValue != newValue && selectedCardModel.selectedCard != nil {
            selectedCardModel.clearSelection()
        }}
    func handleDeepLink(oldValue: UUID?, newValue: UUID?) { // When a card is deep linked from widget, update filters to ensure it's visible
        guard let cardID = newValue else { return }
        
        // Find the card in the context
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate { $0.id == cardID })
        if let card = try? context.fetch(descriptor).first {
            // Update card type filter to include the deep linked card's type
            let cardTypeFilter: CardFilterOption
            switch card.cardType {
            case .todo: cardTypeFilter = .todo
            case .flashcard: cardTypeFilter = .flashcard
            case .note: cardTypeFilter = .note
            }
            
            if !filterOptions.contains(cardTypeFilter) {
                filterOptions.append(cardTypeFilter)
            }
            
            // Update status filter based on card's current state
            let isEnqueued = card.isEnqueue(currentDate: .now) && !card.isArchived
            let isArchived = card.isArchived
            
            if isEnqueued && !filterOptions.contains(.enqueue) {
                filterOptions.append(.enqueue)
            } else if isArchived && !filterOptions.contains(.archived) {
                filterOptions.append(.archived)
            } else if !isEnqueued && !isArchived && !filterOptions.contains(.upcoming) {
                filterOptions.append(.upcoming)
            }
            
            // Expand the appropriate section
            if isEnqueued {
                isQueueExpanded = true
            } else if isArchived {
                isArchivedExpanded = true
            } else {
                isUpcomingExpanded = true
            }
        }
        
        // Reset deepLinkedCardID after processing
        deepLinkedCardID = nil }
    func handleOnAppear() {                 appOpenCount += 1
        Task {
            await CustomizeWidgetTip.appOpenedEvent.donate()
            await GetStartedTip.appOpenedWithoutActionEvent.donate()
        }}
    
    func scrollToCardIDChanged(to newID: UUID?, proxy: ScrollViewProxy) {
        guard let id = newID else { return }
        // Delay slightly to ensure card is rendered and visible in the list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(id, anchor: .center)
            }
        }
        // Reset scrollToCardID after scrolling
        scrollToCardID = nil
    }
    
    func handleSelectionChange(oldID: UUID?, newID: UUID?) {
        // Track the last deselected card for fade-out animation
        if let oldID = oldID, newID != oldID {
            lastDeselectedCardID = oldID
            // Clear after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if lastDeselectedCardID == oldID {
                    lastDeselectedCardID = nil
                }
            }
        }
        
        // When a card is deselected, scroll to it after reordering
        // This keeps the user oriented after the list re-sorts
        if newID == nil, let oldID = oldID {
            // Use priorityChangedForCardID if set, otherwise use the deselected card
            let targetID = priorityChangedForCardID ?? oldID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                scrollToCardID = targetID
                priorityChangedForCardID = nil
            }
        } else if let id = newID {
            scrollToCardID = id
        }
    }
    
    @ViewBuilder
    var addCardButton: some View {
        Button(action: {
            showAddCardActionSheet.toggle()
            addFirstCardTip.invalidate(reason: .actionPerformed)
        }) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4)
        }
        .popoverTip(addFirstCardTip)
        .padding(.trailing, 16)
        .padding(.bottom, 16)
        .accessibilityIdentifier("addCard")
        .accessibilityLabel("Add Card")
        .confirmationDialog("Add Card", isPresented: $showAddCardActionSheet) {
            Button {
                addCard(ofType: .note)
            } label: {
                Label("Note", systemImage: CardType.note.systemImage)
            }
            .accessibilityIdentifier("AddNoteButton")
            
            Button {
                addCard(ofType: .todo)
            } label: {
                Label("To-do", systemImage: CardType.todo.systemImage)
            }
            .accessibilityIdentifier("AddTodoButton")
            
            Button {
                addCard(ofType: .flashcard)
            } label: {
                Label("Flashcard", systemImage: CardType.flashcard.systemImage)
            }
            .accessibilityIdentifier("AddFlashcardButton")
            
            if #available(iOS 26.0, *) {
                Button {
                    showAIGeneratorFromDialog = true
                } label: {
                    Label("Generate with AI", systemImage: "sparkles")
                }
                .accessibilityIdentifier("AddWithAIButton")
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAIGeneratorFromDialog) {
            AICardGeneratorWrapper(
                currentFolder: currentFolderForNewCard,
                currentTagIDs: currentSelectedTagIDs(),
                onCardsCreated: { cards in
                    // Scroll to the first created card after a short delay
                    if let firstCard = cards.first {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            scrollToCardID = firstCard.id
                        }
                    }
                }
            )
        }
    }
}
