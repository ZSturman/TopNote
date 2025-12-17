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

    @EnvironmentObject var selectedCardModel: SelectedCardModel
    let onDelete: ([Card], IndexSet) -> Void
    var onPriorityChanged: ((UUID) -> Void)? = nil
    var priorityChangedForCardID: UUID? = nil
    var lastDeselectedCardID: UUID? = nil

    @Environment(\.ascending) private var ascending: Bool
    
    // Track the card IDs in the order they were when selection started
    // This prevents visual reordering during editing
    @State private var frozenOrder: [UUID] = []

    private var sortedCards: [Card] {
        let sorted = cards.sorted(by: { card1, card2 in
            // Normal sorting: priority first, then nextTimeInQueue, then ID for stability
            if card1.priority.sortValue != card2.priority.sortValue {
                return card1.priority.sortValue < card2.priority.sortValue
            }
            if card1.nextTimeInQueue != card2.nextTimeInQueue {
                return ascending
                    ? card1.nextTimeInQueue < card2.nextTimeInQueue
                    : card1.nextTimeInQueue > card2.nextTimeInQueue
            }
            // Use ID as stable tiebreaker
            return card1.id.uuidString < card2.id.uuidString
        })
        
        // When a card is selected, freeze the order to prevent jarring jumps
        if selectedCardModel.selectedCard != nil {
            // If we haven't captured the frozen order yet, do it now
            if frozenOrder.isEmpty {
                DispatchQueue.main.async {
                    frozenOrder = sorted.map { $0.id }
                }
            }
            
            // If we have a frozen order, use it to maintain visual stability
            if !frozenOrder.isEmpty {
                let cardDict = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0) })
                // Return cards in the frozen order, filtering out any that no longer exist
                let reordered = frozenOrder.compactMap { cardDict[$0] }
                // Add any new cards that weren't in the frozen order at the end
                let newCards = sorted.filter { !frozenOrder.contains($0.id) }
                return reordered + newCards
            }
        } else {
            // No card selected, clear frozen order for next time
            if !frozenOrder.isEmpty {
                DispatchQueue.main.async {
                    frozenOrder = []
                } 
            }
        }
        
        return sorted
    }

    var body: some View {
        Section {
            ForEach(sortedCards) { card in
                CardRow(
                    card: card,
                    onPriorityChanged: onPriorityChanged,
                    lastDeselectedCardID: lastDeselectedCardID
                )
                // Added .id(card.id) for programmatic scrolling support
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
    }

    // Single-select logic: selecting a card deselects any previously selected card
    func select(_ card: Card) {
        if selectedCardModel.selectedCard?.id == card.id {
            // Deselecting by tapping selected card: treat as Done behavior
            if let selected = selectedCardModel.selectedCard {
                let isEmpty = selected.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                if isEmpty {
                    context.delete(selected)
                }
                try? context.save()
            }
            selectedCardModel.clearSelection()
        } else {
            selectedCardModel.selectedCard = card
            selectedCardModel.setIsNewlyCreated(false)
            selectedCardModel.captureSnapshot()
        }
    }

}
