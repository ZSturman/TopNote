//
//  CardStatusSection.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

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
    @State private var frozenOrderSet: Set<UUID> = []  // O(1) lookup optimization for large card counts
    @State private var lastSelectedCardID: UUID? = nil
    
    // Cached sorted cards to prevent redundant sorting
    @State private var cachedSortedCards: [Card] = []
    @State private var lastCardCount: Int = 0
    @State private var lastCardHash: Int = 0
    @State private var lastSortHash: Int = 0  // Tracks sort-affecting properties
    
    // Debounce timer for sort updates after property changes
    @State private var pendingSortUpdate: Task<Void, Never>? = nil
    @State private var pendingReorderTask: Task<Void, Never>? = nil  // Debounced reorder
    
    // Debounce interval in seconds - prevents rapid reordering during edits
    private let sortDebounceInterval: TimeInterval = 0.7

    /// Computes the sorted order without considering frozen order
    /// Used to capture the correct display order before freezing
    private func computeSortedOrder() -> [Card] {
        print("❄️ [COMPUTESORTEDORDER] Computing sorted order for \(cards.count) cards")
        let sorted = cards.sorted(by: { card1, card2 in
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
        print("❄️ [COMPUTESORTEDORDER] Sorted \(sorted.count) cards")
        return sorted
    }
    
    /// Captures frozen order efficiently - only called when selection changes
    /// This prevents O(n²) operations by using Set for lookups
    private func captureFrozenOrder() {
        print("📌 [CAPTUREDFROZENORDER] Capturing frozen order")
        let sorted = computeSortedOrder()
        frozenOrder = sorted.map { $0.id }
        frozenOrderSet = Set(frozenOrder)  // O(1) lookup for filter operations
        print("📌 [CAPTUREDFROZENORDER] Captured \(frozenOrder.count) card IDs")
    }
    
    /// Clears frozen order state
    private func clearFrozenOrder() {
        print("🧯 [CLEARFROZENORDER] Clearing frozen order (had \(frozenOrder.count) items)")
        frozenOrder = []
        frozenOrderSet = []
    }

    /// Computes a hash for the current cards array to detect changes
    private var currentCardHash: Int {
        cards.reduce(0) { $0 ^ $1.id.hashValue }
    }
    
    /// Computes a hash for sort-affecting properties only (priority, nextTimeInQueue)
    /// Content is only included when sorting by content
    private var currentSortHash: Int {
        cards.reduce(0) { hash, card in
            var cardHash = card.id.hashValue
            cardHash ^= card.priority.sortValue.hashValue
            cardHash ^= card.nextTimeInQueue.hashValue
            if sortCriteria == .content {
                cardHash ^= card.content.hashValue
            }
            return hash ^ cardHash
        }
    }
    
    /// Refreshes the cached sorted cards if needed
    private func refreshSortedCacheIfNeeded() {
        let hash = currentCardHash
        guard lastCardCount != cards.count || lastCardHash != hash || cachedSortedCards.isEmpty else {
            print("💾 [SORTCACHE] Cache still valid for \(cards.count) cards")
            return // Cache is still valid
        }
        
        print("💾 [SORTCACHE] Refreshing sorted cache for \(cards.count) cards")
        
        // Update cache tracking
        lastCardCount = cards.count
        lastCardHash = hash
        
        // Compute sorted cards
        if !frozenOrder.isEmpty {
            print("💾 [SORTCACHE] Using frozen order with \(frozenOrder.count) items")
            let cardDict = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
            let reordered = frozenOrder.compactMap { cardDict[$0] }
            let newCards = cards.filter { !frozenOrderSet.contains($0.id) }
            cachedSortedCards = reordered + newCards
        } else {
            cachedSortedCards = computeSortedOrder()
        }
        print("💾 [SORTCACHE] Cached \(cachedSortedCards.count) sorted cards")
    }
    
    /// Schedules a debounced reorder when sort-affecting properties change
    /// This prevents rapid reordering during editing while ensuring eventual consistency
    private func scheduleDebounceReorder() {
        // Cancel any pending reorder
        pendingReorderTask?.cancel()
        
        // Don't debounce if frozen (user is actively editing)
        guard frozenOrder.isEmpty else {
            print("⏳ [REORDER] Skipping debounce - frozen order active")
            return
        }
        
        print("⏳ [REORDER] Scheduling debounced reorder in \(sortDebounceInterval)s")
        
        pendingReorderTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: UInt64(sortDebounceInterval * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                print("⏳ [REORDER] Debounce complete - executing reorder")
                
                // Update sort hash tracking
                lastSortHash = currentSortHash
                
                // Recompute sorted cards with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    cachedSortedCards = computeSortedOrder()
                }
                
                // Trigger widget reload after reorder settles
                WidgetCenter.shared.reloadAllTimelines()
                
            } catch {
                // Task was cancelled - that's fine
            }
        }
    }

    private var sortedCards: [Card] {
        // Return cached value - actual computation happens in refreshSortedCacheIfNeeded()
        // which is called from .onAppear and .onChange
        if cachedSortedCards.isEmpty && !cards.isEmpty {
            // First access before onAppear - compute synchronously and cache it
            // Note: Can't mutate @State in computed property directly, 
            // but the value will be cached on the next refresh
            if !frozenOrder.isEmpty {
                let cardDict = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
                let reordered = frozenOrder.compactMap { cardDict[$0] }
                let newCards = cards.filter { !frozenOrderSet.contains($0.id) }
                print("🔄 [SORTEDCARDS] Initial sync compute with frozen order: \(reordered.count + newCards.count) cards")
                return reordered + newCards
            } else {
                print("🔄 [SORTEDCARDS] Initial sync compute: \(cards.count) cards")
                return computeSortedOrder()
            }
        }
        return cachedSortedCards
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
                    // Use transaction to control animation - only animate the row expansion/collapse
                    .transaction { transaction in
                        // Keep animations light to prevent choppiness
                        transaction.animation = .easeInOut(duration: 0.15)
                    }
                    // NOTE: Per-row animation removed - causes O(n) state tracking with 1000+ cards
                }
            }
            .onDelete { offsets in
                onDelete(sortedCards, offsets)
            }
        }
        .onAppear {
            lastSortHash = currentSortHash
            refreshSortedCacheIfNeeded()
        }
        .onChange(of: cards) { _, _ in
            // Check if sort-affecting properties changed
            let newHash = currentSortHash
            if lastSortHash != newHash {
                // Sort order may need updating - schedule debounced reorder
                scheduleDebounceReorder()
            } else if lastCardCount != cards.count {
                // Only count changed (card added/removed) - immediate refresh
                refreshSortedCacheIfNeeded()
            }
        }
        // Handle frozen order clearing on deselection with debounce
        .onChange(of: selectedCardModel.selectedCard?.id) { oldID, newID in
            if newID == nil && oldID != nil {
                // Card deselected - debounce clearing frozen order
                scheduleFrozenOrderClear()
            }
            // Refresh cache when selection changes
            refreshSortedCacheIfNeeded()
            // Note: Frozen order is now captured in select() BEFORE selection changes
        }
        // Handle priority changes - ensure frozen order is set and extend freeze period
        .onChange(of: priorityChangedForCardID) { oldID, newID in
            if newID != nil && selectedCardModel.selectedCard != nil {
                // Priority changed while a card is selected
                // Ensure frozen order is captured (defensive, should already be set)
                if frozenOrder.isEmpty {
                    captureFrozenOrder()
                }
                // Cancel any pending clear to extend the freeze
                pendingSortUpdate?.cancel()
            }
        }
        // Refresh cache when frozen order changes
        .onChange(of: frozenOrder) { _, _ in
            refreshSortedCacheIfNeeded()
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
                        clearFrozenOrder()
                    }
                }
            } catch {
                // Task was cancelled - that's fine
            }
        }
    }

    /// Single-select logic: selecting a card deselects any previously selected card.
    /// Uses the unified selection method on SelectedCardModel for consistent behavior.
    func select(_ card: Card) {
        print("👆 [SELECT] Selecting card: \(card.id)")
        selectedCardModel.select(
            card: card,
            in: context,
            isNew: false,
            willSelect: { [self] in
                print("👆 [SELECT] willSelect callback - about to capture frozen order")
                // Cancel any pending frozen order clear
                pendingSortUpdate?.cancel()
                
                // IMPORTANT: Capture frozen order BEFORE changing selection
                // This ensures we freeze the exact visual order the user sees
                // Use optimized capture method that also builds the Set for O(1) lookups
                captureFrozenOrder()
            },
            willDeselect: { [self] in
                print("👆 [SELECT] willDeselect callback - deselecting by tapping selected card")
                // Deselecting by tapping selected card
                try? context.save()
                selectedCardModel.clearSelection()
            },
            saveBeforeDeselect: false  // We handle saving in willDeselect
        )
    }

}
