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
    func addCard(ofType type: CardType) {
        let wasEmptyBeforeInsert = cards.isEmpty
        // Force Upcoming filter and remove Enqueue filter to avoid conflicts
        if !filterOptions.contains(.upcoming) {
            filterOptions.append(.upcoming)
        }
        // Expand Upcoming section for focus on new card
        // Keep Queue section state as-is to avoid confusing the user
        isUpcomingExpanded = true
        
        let folderForNew: Folder? = {
            guard let sel = selectedFolder else { return nil }
            if case .folder(let f) = sel { return f }
            return nil
        }()
        
        // Gather tags corresponding to selected tag IDs
        let selectedTagIDs = currentSelectedTagIDs()
        let tagsForNew: [CardTag] = self.tags.filter { selectedTagIDs.contains($0.id) }
        
        // Set type-specific properties
        let isRecurring = true
        let skipEnabled: Bool
        let skipPolicy: RepeatPolicy
        let resetRepeatIntervalOnComplete: Bool
        let repeatInterval: Int
        
        switch type {
        case .flashcard:
            skipEnabled = false
            skipPolicy = .none
            resetRepeatIntervalOnComplete = false
            repeatInterval = 1440
        case .todo:
            skipEnabled = true
            skipPolicy = .aggressive
            resetRepeatIntervalOnComplete = true
            repeatInterval = 720
        case .note:
            skipEnabled = true
            skipPolicy = .mild
            resetRepeatIntervalOnComplete = false
            repeatInterval = 2880
        }
        
        let newCard = Card(
            createdAt: Date(),
            cardType: type,
            priorityTypeRaw: .none,
            content: "",
            isRecurring: isRecurring,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: repeatInterval,
            initialRepeatInterval: repeatInterval,
            folder: folderForNew,
            tags: tagsForNew,
            skipPolicy: skipPolicy,
            ratingEasyPolicy: .mild,
            ratingMedPolicy: .none,
            ratingHardPolicy: .aggressive,
            isComplete: false,
            resetRepeatIntervalOnComplete: resetRepeatIntervalOnComplete,
            skipEnabled: skipEnabled
            
        )
        
        context.insert(newCard)
        selectedCardModel.selectedCard = newCard
        selectedCardModel.setIsNewlyCreated(true)
        // Capture snapshot of the brand-new state so Cancel can delete instead of revert
        selectedCardModel.captureSnapshot()
        
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
            switch type {
            case .note:
                await FirstNoteTip_Skip.createdFirstNoteEvent.donate()
            case .todo:
                await FirstTodoTip_Skip.createdFirstTodoEvent.donate()
            case .flashcard:
                await FirstFlashcardTip_Skip.createdFirstFlashcardEvent.donate()
            }
        }
        
        // Scroll to new card after a brief delay to ensure it's rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToCardID = newCard.id
        }
    }
    func delete(cards sectionCards: [Card], at offsets: IndexSet) {
        let toDelete = offsets.map { sectionCards[$0] }
        toDelete.forEach { context.delete($0) }
        do {
            try context.save()
        } catch {
            // Handle error here if desired
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
            print("Failed to delete orphaned tags: \(error)")
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
        // Scroll to new card if visible, or to the upcoming section if not
        // Try scrolling to the card row. If not found, scroll to Upcoming section.
        withAnimation {
            proxy.scrollTo(id, anchor: .center)
        }
        // Reset scrollToCardID after scrolling
        scrollToCardID = nil}
    
    func handleSelectionChange(oldID: UUID?, newID: UUID?) {
        // When a card is deselected and its priority changed, scroll to it after reordering
        if newID == nil, let changedCardID = priorityChangedForCardID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                scrollToCardID = changedCardID
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
        .accessibilityLabel("Add Card")
        .confirmationDialog("Add Card", isPresented: $showAddCardActionSheet) {
            Button("Note") { addCard(ofType: .note) }
            Button("Todo") { addCard(ofType: .todo) }
            Button("Flashcard") { addCard(ofType: .flashcard) }
            Button("Cancel", role: .cancel) {}
        }
    }
}
