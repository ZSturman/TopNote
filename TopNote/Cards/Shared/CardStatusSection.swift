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
    
    // Multi-select support
    var selectionMode: Bool = false
    var selectedCards: Binding<Set<Card>>? = nil

    @Environment(\.ascending) private var ascending: Bool
    @Environment(\.sortCriteria) private var sortCriteria: CardSortCriteria
    
    // Track the card IDs in the order they were when selection started
    // This prevents visual reordering during editing
    @State private var frozenOrder: [UUID] = []
    @State private var lastSelectedCardID: UUID? = nil
    
    // Debounce timer for sort updates after property changes
    @State private var pendingSortUpdate: Task<Void, Never>? = nil
    
    // Debounce interval in seconds - prevents rapid reordering during edits
    private let sortDebounceInterval: TimeInterval = 0.3

    /// Computes the sorted order without considering frozen order
    /// Used to capture the correct display order before freezing
    private func computeSortedOrder() -> [Card] {
        cards.sorted(by: { card1, card2 in
            // For content sorting, use alphabetical comparison
            if sortCriteria == .content {
                let comparison = card1.content.localizedStandardCompare(card2.content)
                if comparison != .orderedSame {
                    return ascending
                        ? comparison == .orderedAscending
                        : comparison == .orderedDescending
                }
                // Fall back to createdAt for equal content
                if card1.createdAt != card2.createdAt {
                    return card1.createdAt > card2.createdAt
                }
                return card1.id.uuidString < card2.id.uuidString
            }
            
            // Default sorting: priority first, then by criteria
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
        
        // Use frozen order if we have one and a card is selected or was recently deselected
        // This prevents jarring reordering during and shortly after editing
        if !frozenOrder.isEmpty {
            let cardDict = Dictionary(uniqueKeysWithValues: sorted.map { ($0.id, $0) })
            let reordered = frozenOrder.compactMap { cardDict[$0] }
            let newCards = sorted.filter { !frozenOrder.contains($0.id) }
            return reordered + newCards
        }
        
        return sorted
    }

    var body: some View {
        Section {
            ForEach(sortedCards, id: \.id) { card in
                if selectionMode, let selectedCards = selectedCards {
                    // Multi-select mode: show checkmark and toggle selection on tap
                    HStack {
                        Image(
                            systemName: selectedCards.wrappedValue.contains(card)
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundColor(
                            selectedCards.wrappedValue.contains(card)
                                ? .accentColor : .secondary
                        )
                        .font(.title3)
                        
                        CardRow(
                            card: card,
                            folders: folders,
                            onPriorityChanged: onPriorityChanged,
                            lastDeselectedCardID: lastDeselectedCardID
                        )
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedCards.wrappedValue.contains(card) {
                            selectedCards.wrappedValue.remove(card)
                        } else {
                            selectedCards.wrappedValue.insert(card)
                        }
                    }
                } else {
                    // Normal mode: single card editing
                    CardRow(
                        card: card,
                        folders: folders,
                        onPriorityChanged: onPriorityChanged,
                        lastDeselectedCardID: lastDeselectedCardID
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                    .onTapGesture { select(card) }
                    .accessibilityAddTraits(.isButton)
                    .animation(.easeInOut(duration: 0.2), value: selectedCardModel.selectedCard?.id)
                }
            }
            .onDelete { offsets in
                onDelete(sortedCards, offsets)
            }
        }
        // Handle frozen order clearing on deselection with debounce
        .onChange(of: selectedCardModel.selectedCard?.id) { oldID, newID in
            if newID == nil && oldID != nil {
                // Card deselected - debounce clearing frozen order
                scheduleFrozenOrderClear()
            }
            // Note: Frozen order is now captured in select() BEFORE selection changes
        }
        // Handle priority changes - extend frozen period when priority changes
        .onChange(of: priorityChangedForCardID) { oldID, newID in
            if newID != nil && selectedCardModel.selectedCard != nil {
                // Priority changed while a card is selected - extend freeze
                scheduleFrozenOrderClear()
            }
        }
    }
    
    /// Schedules clearing the frozen order with debounce to prevent rapid reordering
    private func scheduleFrozenOrderClear() {
        // Cancel any pending update
        pendingSortUpdate?.cancel()
        
        // Schedule new debounced clear
        pendingSortUpdate = Task { @MainActor in
            do {
                // Wait for debounce interval
                try await Task.sleep(nanoseconds: UInt64(0.8 * 1_000_000_000))
                
                // Only clear if no card is selected
                if selectedCardModel.selectedCard == nil {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        frozenOrder = []
                    }
                }
            } catch {
                // Task was cancelled - that's fine
            }
        }
    }

    /// Single-select logic: selecting a card deselects any previously selected card.
    /// Uses UUID-based selection to ensure fresh card references are fetched from the context.
    func select(_ card: Card) {
        if selectedCardModel.selectedCard?.id == card.id {
            // Deselecting by tapping selected card
            try? context.save()
            selectedCardModel.clearSelection()
        } else {
            // Cancel any pending frozen order clear
            pendingSortUpdate?.cancel()
            
            // IMPORTANT: Capture frozen order BEFORE changing selection
            // This ensures we freeze the exact visual order the user sees
            if selectedCardModel.selectedCard == nil {
                // Only freeze when going from no selection to selection
                // (not when switching between cards)
                frozenOrder = computeSortedOrder().map { $0.id }
            }
            
            // Use UUID-based selection to ensure we get a fresh reference from the context
            // This prevents stale reference issues that can cause crashes
            selectedCardModel.selectCard(with: card.id, modelContext: context, isNew: false)
        }
    }

}
