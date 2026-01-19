//
//  CardListView+Filtering.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

extension CardListView {
    var activeStatusFilters: Set<CardFilterOption> {
        Set(filterOptions.filter { CardFilterOption.statusFilters.contains($0) })
    }
    
    var activeTypeFilters: Set<CardFilterOption> {
        Set(filterOptions.filter { CardFilterOption.typeFilters.contains($0) })
    }
    
    var allSelectableCards: [Card] { filteredCards }

    var allCardsSelected: Bool {
        !allSelectableCards.isEmpty
            && selectedCards.count == allSelectableCards.count
    }

    func selectAllCards() { selectedCards = Set(allSelectableCards)}

    func deselectAllCards() { selectedCards.removeAll() }

    func currentSelectedTagIDs() -> [UUID] {
        tagSelectionStates.compactMap { (id, state) in
            state == .selected ? id : nil
        }
    }
    func currentDeselectedTagIDs() -> [UUID] {
        tagSelectionStates.compactMap { (id, state) in
            state == .deselected ? id : nil
        }
    }
    
    // MARK: - Debounced Section Refresh
    /// Schedules a debounced section refresh when cards move between sections
    /// Triggers after 0.7s of inactivity to batch rapid changes
    func scheduleDebouncedSectionRefresh() {
        pendingSectionRefreshTask?.cancel()
        
        print("⏳ [SECTION] Scheduling debounced section refresh in 0.7s")
        
        pendingSectionRefreshTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: UInt64(0.7 * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                print("⏳ [SECTION] Debounce complete - refreshing sections")
                
                lastSectionHash = computeSectionHash()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    refreshCacheIfNeeded()
                }
                
                // Trigger widget reload after sections update
                WidgetCenter.shared.reloadAllTimelines()
                
            } catch {
                // Task was cancelled
            }
        }
    }
    
    // MARK: - Cache Refresh
    /// Refreshes all cached card lists if the cache key has changed.
    /// Call this when any filter input changes.
    func refreshCacheIfNeeded() {
        let newKey = currentCacheKey
        guard lastCacheKey != newKey else {
            print("📦 [CACHE] Cache still valid, skipping refresh")
            return
        }
        
        print("📦 [CACHE] Refreshing cache - cards: \(cards.count)")
        lastCacheKey = newKey
        
        // Compute filtered cards once with deduplication
        let filtered = computeFilteredCards()
        cachedFilteredCards = deduplicateCards(filtered)
        
        // Pre-compute all derived lists from the single filtered result
        cachedQueueCards = cachedFilteredCards.filter {
            !$0.isDeleted && $0.isEnqueue(currentDate: Date.now) && !$0.isArchived
        }
        cachedUpcomingCards = cachedFilteredCards.filter {
            !$0.isDeleted && !$0.isEnqueue(currentDate: Date.now) && !$0.isArchived
        }
        cachedArchivedCards = cachedFilteredCards.filter { 
            !$0.isDeleted && $0.isArchived 
        }.sorted { card1, card2 in
            let date1 = card1.removals.last ?? card1.createdAt
            let date2 = card2.removals.last ?? card2.createdAt
            return date1 > date2
        }
        cachedDeletedCards = cachedFilteredCards.filter { 
            $0.isDeleted 
        }.sorted { card1, card2 in
            let date1 = card1.deletedAt ?? card1.createdAt
            let date2 = card2.deletedAt ?? card2.createdAt
            return date1 > date2
        }
        
        // Compute card counts (using all cards filtered by status only, not type)
        let statusFiltered = computeCardsFilteredExcludingType()
        cachedCardCounts = (
            todo: statusFiltered.filter { $0.cardType == .todo }.count,
            note: statusFiltered.filter { $0.cardType == .note }.count,
            flashcard: statusFiltered.filter { $0.cardType == .flashcard }.count
        )
        
        print("📦 [CACHE] Refresh complete - filtered: \(cachedFilteredCards.count), queue: \(cachedQueueCards.count), upcoming: \(cachedUpcomingCards.count)")
    }
    
    /// Removes duplicate cards by ID, keeping only the first occurrence
    private func deduplicateCards(_ cards: [Card]) -> [Card] {
        var seen = Set<UUID>()
        var result: [Card] = []
        for card in cards {
            if !seen.contains(card.id) {
                seen.insert(card.id)
                result.append(card)
            } else {
                print("⚠️ [DEDUPE] Duplicate card found: \(card.id)")
            }
        }
        return result
    }

    /// Use cached filtered cards instead of recomputing
    var filteredCards: [Card] {
        // Return cached value - refresh happens via onChange handlers
        return cachedFilteredCards
    }
    
    /// Internal function that actually computes filtered cards
    private func computeFilteredCards() -> [Card] {
        print("🔍 [COMPUTE] Computing filteredCards - Total cards: \(cards.count)")
        // Extract which type and status filters are selected, if any
        let typeFilters = Set(
            filterOptions.filter { CardFilterOption.typeFilters.contains($0) }
        )
        let selectedCardTypes = Set(typeFilters.compactMap { $0.asCardType })
        let statusFilters = activeStatusFilters
        print("🔍 [FILTEREDCARDS] Status filters: \(statusFilters)")
//        let attributeFilters = Set(
//            filterOptions.filter { CardFilterOption.attributeFilters.contains($0) }
//        )

        // Apply type filter - if no types selected, show no cards
        let typeFiltered: [Card] =
            selectedCardTypes.isEmpty
            ? []
            : cards.filter { selectedCardTypes.contains($0.cardType) }

        // Apply status filter if any status options selected
        // Status filters now include: enqueue, upcoming, archived, deleted
        // Each status is independent - a card matches if it belongs to ANY selected status
        let statusFiltered: [Card] =
            statusFilters.isEmpty
            ? typeFiltered
            : typeFiltered.filter { card in
                // Deleted cards only match the .deleted status
                if card.isDeleted {
                    return statusFilters.contains(.deleted)
                }
                
                // Non-deleted cards match their respective status
                let isEnqueue =
                    card.isEnqueue(currentDate: .now) && !card.isArchived
                let isUpcoming =
                    !card.isEnqueue(currentDate: .now) && !card.isArchived
                let isArchived = card.isArchived
                
                var matched = false
                if statusFilters.contains(.enqueue), isEnqueue {
                    matched = true
                }
                if statusFilters.contains(.upcoming), isUpcoming {
                    matched = true
                }
                if statusFilters.contains(.archived), isArchived {
                    matched = true
                }
                return matched
            }

        // Apply attribute filters (e.g., has attachment)
        // MARK: - IMAGE DISABLED
        let attributeFiltered: [Card] = statusFiltered
        /* ORIGINAL ATTRIBUTE FILTER CODE:
        let attributeFiltered: [Card] =
            attributeFilters.isEmpty
            ? statusFiltered
            : statusFiltered.filter { card in
                var matched = true
                if attributeFilters.contains(.hasAttachment) {
                    // Card must have at least one attachment
                    matched = matched && (card.contentImageData != nil || card.answerImageData != nil)
                }
                return matched
            }
        */

        // Folder filtering as before
        let folderFiltered: [Card] = {
            guard let selected = selectedFolder else { return attributeFiltered }
            switch selected {
            case .folder(let folder):
                return attributeFiltered.filter { $0.folder?.id == folder.id }
            case .allCards:
                return attributeFiltered
            }
        }()

        // Tag selection filtering
        // Selected tags use OR logic: card must have AT LEAST ONE of the selected tags
        // Deselected tags use exclusion: card must have NONE of the deselected tags
        let selectedTagIDs = currentSelectedTagIDs()
        let deselectedTagIDs = currentDeselectedTagIDs()

        let tagFiltered = folderFiltered.filter { card in
            let tagIDs = Set(card.unwrappedTags.map { $0.id })
            // Must contain at least one selected tag ID (OR logic)
            if !selectedTagIDs.isEmpty
                && !selectedTagIDs.contains(where: { tagIDs.contains($0) })
            {
                return false
            }
            // Must not contain any deselected tag IDs
            if !deselectedTagIDs.isEmpty
                && deselectedTagIDs.contains(where: { tagIDs.contains($0) })
            {
                return false
            }
            return true
        }
        
        // Apply search filter if search text is not empty
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            print("🔍 [FILTEREDCARDS] Final count (no search): \(tagFiltered.count)")
            return tagFiltered
        }
        
        let searchTerm = searchText.lowercased()
        print("🔍 [FILTEREDCARDS] Applying search filter: '\(searchTerm)'")
        let searchFiltered = tagFiltered.filter { card in
            // Search in content
            if card.content.lowercased().contains(searchTerm) {
                return true
            }
            // Search in answer (for flashcards)
            if let answer = card.answer, answer.lowercased().contains(searchTerm) {
                return true
            }
            // Search in tags
            if card.unwrappedTags.contains(where: { $0.name.lowercased().contains(searchTerm) }) {
                return true
            }
            return false
        }
        print("🔍 [FILTEREDCARDS] Final count (with search): \(searchFiltered.count)")
        return searchFiltered
    }

    var shouldShowQueueSection: Bool {
        activeStatusFilters.contains(.enqueue)
    }

    var shouldShowUpcomingSection: Bool {
        activeStatusFilters.contains(.upcoming)
    }

    var shouldShowArchivedSection: Bool {
        activeStatusFilters.contains(.archived)
    }
    
    /// Returns true when the deleted status filter is selected
    var shouldShowDeletedSection: Bool {
        activeStatusFilters.contains(.deleted)
    }

    func groupCardsByDay(_ cards: [Card]) -> [Date: [Card]] {
        let calendar = Calendar.current
        return Dictionary(grouping: cards) { card in
            calendar.startOfDay(for: card.createdAt)
        }
    }

    func displayDateHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    /// Cards filtered by all criteria EXCEPT card type - used for computing type counts
    /// Changed to a function so it can be called from refreshCacheIfNeeded()
    private func computeCardsFilteredExcludingType() -> [Card] {
        let statusFilters = activeStatusFilters
        
        // Start with all cards, no type filter applied
        let allCards = cards
        
        // Apply status filter if any status options selected
        let statusFiltered: [Card] =
            statusFilters.isEmpty
            ? allCards
            : allCards.filter { card in
                // Deleted cards only match the .deleted status
                if card.isDeleted {
                    return statusFilters.contains(.deleted)
                }
                
                // Non-deleted cards match their respective status
                let isEnqueue =
                    card.isEnqueue(currentDate: .now) && !card.isArchived
                let isUpcoming =
                    !card.isEnqueue(currentDate: .now) && !card.isArchived
                let isArchived = card.isArchived
                
                var matched = false
                if statusFilters.contains(.enqueue), isEnqueue {
                    matched = true
                }
                if statusFilters.contains(.upcoming), isUpcoming {
                    matched = true
                }
                if statusFilters.contains(.archived), isArchived {
                    matched = true
                }
                return matched
            }
        
        // Apply attribute filters (currently disabled)
        let attributeFiltered: [Card] = statusFiltered
        
        // Folder filtering
        let folderFiltered: [Card] = {
            guard let selected = selectedFolder else { return attributeFiltered }
            switch selected {
            case .folder(let folder):
                return attributeFiltered.filter { $0.folder?.id == folder.id }
            case .allCards:
                return attributeFiltered
            }
        }()
        
        // Tag selection filtering
        let selectedTagIDs = currentSelectedTagIDs()
        let deselectedTagIDs = currentDeselectedTagIDs()
        
        let tagFiltered = folderFiltered.filter { card in
            let tagIDs = Set(card.unwrappedTags.map { $0.id })
            // Must contain at least one selected tag ID (OR logic)
            if !selectedTagIDs.isEmpty
                && !selectedTagIDs.contains(where: { tagIDs.contains($0) })
            {
                return false
            }
            // Must not contain any deselected tag IDs
            if !deselectedTagIDs.isEmpty
                && deselectedTagIDs.contains(where: { tagIDs.contains($0) })
            {
                return false
            }
            return true
        }
        
        // Apply search filter if search text is not empty
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            print("🔍 [CARDSEXCLUDINGTYPE] Final count (no search): \(tagFiltered.count)")
            return tagFiltered
        }
        
        let searchTerm = searchText.lowercased()
        print("🔍 [CARDSEXCLUDINGTYPE] Applying search filter: '\(searchTerm)'")
        let searchFiltered = tagFiltered.filter { card in
            // Search in content
            if card.content.lowercased().contains(searchTerm) {
                return true
            }
            // Search in answer (for flashcards)
            if let answer = card.answer, answer.lowercased().contains(searchTerm) {
                return true
            }
            // Search in tags
            if card.unwrappedTags.contains(where: { $0.name.lowercased().contains(searchTerm) }) {
                return true
            }
            return false
        }
        print("🔍 [CARDSEXCLUDINGTYPE] Final count (with search): \(searchFiltered.count)")
        return searchFiltered
    }
    
    var toDoCardCount: Int {
        cachedCardCounts.todo
    }
    
    var noteCardCount: Int {
        cachedCardCounts.note
    }
    
    var flashcardCount: Int {
        cachedCardCounts.flashcard
    }
    

    var queueCards: [Card] {
        // Use cached value - computed in refreshCacheIfNeeded()
        return cachedQueueCards
    }
    var upcomingCards: [Card] {
        // Use cached value - computed in refreshCacheIfNeeded()
        return cachedUpcomingCards
    }
    var archivedCards: [Card] {
        // Use cached value - computed in refreshCacheIfNeeded()
        return cachedArchivedCards
    }
    
    /// Returns soft-deleted cards, sorted by deletion date (most recent first)
    var deletedCards: [Card] {
        // Use cached value - computed in refreshCacheIfNeeded()
        return cachedDeletedCards
    }
    
    var groupedByDay: [Date: [Card]] { 
        print("📆 [GROUPEDBYDAY] Computing groupedByDay from \(filteredCards.count) filtered cards")
        let result = groupCardsByDay(filteredCards)
        print("📆 [GROUPEDBYDAY] Result: \(result.keys.count) days")
        return result
    }
    var sortedKeys: [Date] {
        print("🔑 [SORTEDKEYS] Computing sortedKeys from \(groupedByDay.keys.count) keys")
        let keysArray: [Date] = Array(groupedByDay.keys)
        let result = ascending ? keysArray.sorted(by: { $0 < $1 }) : keysArray.sorted(by: { $0 > $1 })
        print("🔑 [SORTEDKEYS] Result: \(result.count) sorted keys")
        return result
    }
}
