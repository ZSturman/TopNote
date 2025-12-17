//
//  CardStatusSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

struct CardStatusSection: View {
    @Environment(\.modelContext) private var context
    let title: String
    let cards: [Card]
    let folders: [Folder]  // Passed from parent to avoid per-row queries

    @EnvironmentObject var selectedCardModel: SelectedCardModel
    let onDelete: ([Card], IndexSet) -> Void
    var onPriorityChanged: ((UUID) -> Void)? = nil
    var priorityChangedForCardID: UUID? = nil
    var lastDeselectedCardID: UUID? = nil

    @Environment(\.ascending) private var ascending: Bool
    
    // Track the card IDs in the order they were when selection started
    // This prevents visual reordering during editing
    @State private var frozenOrder: [UUID] = []
    @State private var lastSelectedCardID: UUID? = nil

    /// Computes the sorted order without considering frozen order
    /// Used to capture the correct display order before freezing
    private func computeSortedOrder() -> [Card] {
        cards.sorted(by: { card1, card2 in
            if card1.priority.sortValue != card2.priority.sortValue {
                return card1.priority.sortValue < card2.priority.sortValue
            }
            if card1.nextTimeInQueue != card2.nextTimeInQueue {
                return ascending
                    ? card1.nextTimeInQueue < card2.nextTimeInQueue
                    : card1.nextTimeInQueue > card2.nextTimeInQueue
            }
            if card1.createdAt != card2.createdAt {
                return card1.createdAt > card2.createdAt
            }
            return card1.id.uuidString < card2.id.uuidString
        })
    }

    private var sortedCards: [Card] {
        let sorted = computeSortedOrder()
        
        // Use frozen order if we have one and a card is selected
        if selectedCardModel.selectedCard != nil && !frozenOrder.isEmpty {
            let cardDict = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0) })
            let reordered = frozenOrder.compactMap { cardDict[$0] }
            let newCards = sorted.filter { !frozenOrder.contains($0.id) }
            return reordered + newCards
        }
        
        return sorted
    }

    var body: some View {
        Section {
            ForEach(sortedCards) { card in
                CardRow(
                    card: card,
                    folders: folders,
                    onPriorityChanged: onPriorityChanged,
                    lastDeselectedCardID: lastDeselectedCardID
                )
                .id(card.id)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
                .onTapGesture { select(card) }
                .accessibilityAddTraits(.isButton)
                .animation(.default, value: selectedCardModel.selectedCard?.id)
            }
            .onDelete { offsets in
                onDelete(sortedCards, offsets)
            }
        }
        // Handle frozen order clearing on deselection
        .onChange(of: selectedCardModel.selectedCard?.id) { oldID, newID in
            if newID == nil && oldID != nil {
                // Card deselected - delay clearing frozen order to allow scroll to complete
                // This prevents jarring reorder while scrolling is in progress
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    frozenOrder = []
                }
            }
            // Note: Frozen order is now captured in select() BEFORE selection changes
        }
    }

    // Single-select logic: selecting a card deselects any previously selected card
    func select(_ card: Card) {
        if selectedCardModel.selectedCard?.id == card.id {
            // Deselecting by tapping selected card
            try? context.save()
            selectedCardModel.clearSelection()
        } else {
            // IMPORTANT: Capture frozen order BEFORE changing selection
            // This ensures we freeze the exact visual order the user sees
            if selectedCardModel.selectedCard == nil {
                // Only freeze when going from no selection to selection
                // (not when switching between cards)
                frozenOrder = computeSortedOrder().map { $0.id }
            }
            
            // Now update selection
            selectedCardModel.selectedCard = card
            selectedCardModel.setIsNewlyCreated(false)
            selectedCardModel.captureSnapshot()
        }
    }

}
