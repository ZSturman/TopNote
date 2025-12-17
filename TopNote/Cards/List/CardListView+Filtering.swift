//
//  CardListView+Filtering.swift
//  TopNote
//
//  Created by Zachary Sturman on 11/27/25.
//

import Foundation
import SwiftUI
import SwiftData

extension CardListView {
    var activeStatusFilters: Set<CardFilterOption> {
        Set(filterOptions.filter { CardFilterOption.statusFilters.contains($0) })
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

    var filteredCards: [Card] {
        // Extract which type and status filters are selected, if any
        let typeFilters = Set(
            filterOptions.filter { CardFilterOption.typeFilters.contains($0) }
        )
        let selectedCardTypes = Set(typeFilters.compactMap { $0.asCardType })
        let statusFilters = activeStatusFilters
        let attributeFilters = Set(
            filterOptions.filter { CardFilterOption.attributeFilters.contains($0) }
        )

        // Apply type filter if any type options selected
        let typeFiltered: [Card] =
            selectedCardTypes.isEmpty
            ? cards
            : cards.filter { selectedCardTypes.contains($0.cardType) }

        // Apply status filter if any status options selected
        let statusFiltered: [Card] =
            statusFilters.isEmpty
            ? typeFiltered
            : typeFiltered.filter { card in
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

        // Tag selection filtering as before
        let selectedTagIDs = currentSelectedTagIDs()
        let deselectedTagIDs = currentDeselectedTagIDs()

        let tagFiltered = folderFiltered.filter { card in
            let tagIDs = Set(card.unwrappedTags.map { $0.id })
            // Must contain all selected tag IDs
            if !selectedTagIDs.isEmpty
                && !selectedTagIDs.allSatisfy({ tagIDs.contains($0) })
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
            return tagFiltered
        }
        
        let searchTerm = searchText.lowercased()
        return tagFiltered.filter { card in
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

    var queueCards: [Card] {
        let cards = filteredCards.filter {
            $0.isEnqueue(currentDate: .now) && !$0.isArchived
        }
        // When any card is selected, don't apply priority sorting to prevent jarring reorder
        // The actual sorting by priority happens in CardStatusSection, this just returns the base list
        return cards
    }
    var upcomingCards: [Card] {
        let cards = filteredCards.filter {
            !$0.isEnqueue(currentDate: .now) && !$0.isArchived
        }
        // When any card is selected, don't apply priority sorting to prevent jarring reorder
        // The actual sorting by priority happens in CardStatusSection, this just returns the base list
        return cards
    }
    var archivedCards: [Card] {
        filteredCards.filter { $0.isArchived }.sorted { card1, card2 in
            let date1 = card1.removals.last ?? card1.createdAt
            let date2 = card2.removals.last ?? card2.createdAt
            return date1 > date2 // Most recent first
        }
    }
    var groupedByDay: [Date: [Card]] { groupCardsByDay(filteredCards) }
    var sortedKeys: [Date] {
        let keysArray: [Date] = Array(groupedByDay.keys)
        if ascending {
            return keysArray.sorted(by: { $0 < $1 })
        } else {
            return keysArray.sorted(by: { $0 > $1 })
        }
    }
}
