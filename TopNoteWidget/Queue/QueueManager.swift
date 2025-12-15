//
//  QueueManager.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation
import SwiftData
import WidgetKit

struct QueueManager {
    let context: ModelContext

    private func updateEnqueueStatsIfNeeded(for cards: [Card], currentDate: Date) {
        var updatedAny = false

        for card in cards {
            guard card.isEnqueue(currentDate: currentDate) else { continue }

            let lastEnqueue = card.enqueues.last
            let isNewQueueEntry = lastEnqueue == nil || lastEnqueue! < card.nextTimeInQueue

            if isNewQueueEntry {
                card.seenCount += 1
                card.enqueues.append(currentDate)
                updatedAny = true
            }
        }

        if updatedAny {
            try? context.save()
        }
    }

    func fetchQueueCards(currentDate: Date, configuration: ConfigurationAppIntent) throws -> [Card] {
        let fetched = try context.fetch(FetchDescriptor<Card>())

        let selectedTypes = configuration.showCardType
        let filterByTypes = !selectedTypes.isEmpty

        // Only filter by folders if the user explicitly selected something.
        let filterByFolders = !configuration.showFolders.isEmpty

        // Work from the actual selected folders (NOT effectiveFolders),
        // because effectiveFolders includes everything when nothing is selected.
        let selectedFolderIDs = Set(configuration.showFolders.map(\.id))
        let includesNoFolder = configuration.showFolders.contains(where: { $0.isNoFolderSentinel })

        let filtered = fetched.filter { card in
            guard card.isEnqueue(currentDate: currentDate) else { return false }

            if filterByFolders {
                if let folder = card.folder {
                    // Keep foldered cards only if their folder was selected.
                    guard selectedFolderIDs.contains(folder.id) else { return false }
                } else {
                    // card.folder == nil: only include if "No Folder" was selected.
                    guard includesNoFolder else { return false }
                }
            }

            if filterByTypes {
                guard selectedTypes.contains(card.cardType) else { return false }
            }

            return true
        }

        updateEnqueueStatsIfNeeded(for: filtered, currentDate: currentDate)

        return filtered.sorted {
            ($0.priority.sortValue, $0.nextTimeInQueue) < ($1.priority.sortValue, $1.nextTimeInQueue)
        }
    }

    func fetchQueueCardsAndSummary(
        currentDate: Date,
        configuration: ConfigurationAppIntent
    ) throws -> ([Card], Card?, Int) {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        return (queueCards, queueCards.first, queueCards.count)
    }

    func skipTopCard(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let topCard = queueCards.first else { return }
        topCard.skip(at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func nextTopCard(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let topCard = queueCards.first else { return }
        topCard.next(at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func completeTopCard(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let todoCard = queueCards.first(where: { $0.cardType == .todo }) else { return }
        todoCard.markAsComplete(at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func rateTopFlashcard(
        currentDate: Date,
        configuration: ConfigurationAppIntent,
        rating: Int
    ) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let flashcard = queueCards.first(where: { $0.cardType == .flashcard }) else { return }
        let ratingTypes = RatingType.allCases
        guard rating >= 0 && rating < ratingTypes.count else { return }
        flashcard.submitFlashcardRating(ratingTypes[rating], at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func revealTopCardAnswer(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let flashcard = queueCards.first(where: { $0.cardType == .flashcard }) else { return }
        flashcard.answerRevealed = true
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }
}
