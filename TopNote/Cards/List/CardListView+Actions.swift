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
        
        // Set nextTimeInQueue to slightly in the future so it appears in Upcoming section
        // but near the top (earliest nextTimeInQueue when sorted ascending)
        let now = Date()
        let nextTimeInQueueForNewCard = now.addingTimeInterval(60) // 1 minute from now - puts it in Upcoming but near the top
        
        let newCard = Card(
            createdAt: now,
            cardType: type,
            priorityTypeRaw: .none,
            content: "",
            isRecurring: isRecurring,
            skipCount: 0,
            seenCount: 0,
            repeatInterval: repeatInterval,
            initialRepeatInterval: repeatInterval,
            nextTimeInQueue: nextTimeInQueueForNewCard,
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
        
        // DEBUG: Print card count before insertion
        let fetchDescriptor = FetchDescriptor<Card>()
        let countBefore = (try? context.fetch(fetchDescriptor).count) ?? 0
        print("📝 [ADD CARD] Card count BEFORE insert: \(countBefore)")
        
        context.insert(newCard)
        print("📝 [ADD CARD] Inserted new card with ID: \(newCard.id), content: '\(newCard.content)'")
        
        // DEBUG: Print card count after insertion
        let countAfter = (try? context.fetch(fetchDescriptor).count) ?? 0
        print("📝 [ADD CARD] Card count AFTER insert: \(countAfter)")
        
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
        // Use a longer delay to ensure SwiftUI has time to insert and render the new card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("📝 [ADD CARD] Scrolling to new card ID: \(newCard.id)")
            scrollToCardID = newCard.id
        }
    }
    func delete(cards sectionCards: [Card], at offsets: IndexSet) {
        let toDelete = offsets.map { sectionCards[$0] }
        print("📝 [DELETE] Deleting \(toDelete.count) cards")
        toDelete.forEach { card in
            print("📝 [DELETE] Deleting card ID: \(card.id), content: '\(card.content)'")
            context.delete(card)
        }
        do {
            try context.save()
            print("📝 [DELETE] Context saved successfully")
            
            // DEBUG: Print card count after delete
            let fetchDescriptor = FetchDescriptor<Card>()
            let count = (try? context.fetch(fetchDescriptor).count) ?? 0
            print("📝 [DELETE] Card count after delete: \(count)")
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
        print("📝 [SCROLL] Attempting to scroll to card ID: \(id)")
        // Delay slightly to ensure card is rendered and visible in the list
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo(id, anchor: .center)
            }
            print("📝 [SCROLL] Scroll command sent")
        }
        // Reset scrollToCardID after scrolling
        scrollToCardID = nil
    }
    
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
        .accessibilityIdentifier("addCard")
        .accessibilityLabel("Add Card")
        .confirmationDialog("Add Card", isPresented: $showAddCardActionSheet) {
            Button("Note") { addCard(ofType: .note) }
                .accessibilityIdentifier("AddNoteButton")
            Button("To-do") { addCard(ofType: .todo) }
                .accessibilityIdentifier("AddTodoButton")
            Button("Flashcard") { addCard(ofType: .flashcard) }
                .accessibilityIdentifier("AddFlashcardButton")
            Button("Cancel", role: .cancel) {}
        }
    }
}
