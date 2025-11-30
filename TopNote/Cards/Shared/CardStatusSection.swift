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

    @Environment(\.ascending) private var ascending: Bool

    private var sortedCards: [Card] {
        cards.sorted(by: { card1, card2 in
            // When ANY card is selected, freeze the sort order to prevent jarring jumps
            // This prevents the list from reordering while the user is editing
            if selectedCardModel.selectedCard != nil {
                // Only sort by nextTimeInQueue to keep card positions stable during editing
                return ascending
                    ? card1.nextTimeInQueue < card2.nextTimeInQueue
                    : card1.nextTimeInQueue > card2.nextTimeInQueue
            }
            
            // Normal sorting: priority first, then nextTimeInQueue
            if card1.priority.sortValue != card2.priority.sortValue {
                return card1.priority.sortValue < card2.priority.sortValue
            }
            return ascending
                ? card1.nextTimeInQueue < card2.nextTimeInQueue
                : card1.nextTimeInQueue > card2.nextTimeInQueue
        })
    }

    var body: some View {
        Section {
            ForEach(sortedCards) { card in
                CardRow(
                    card: card,
                    onPriorityChanged: onPriorityChanged
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
