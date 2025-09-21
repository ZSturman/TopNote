//
//  QueueManager.swift
//  TopNoteWidgetExtension
//
//  Created by Zachary Sturman on 2/19/25.
//
import Foundation
import SwiftData
import WidgetKit

struct QueueManager {
    let context: ModelContext

    // Helper: Fetch queued cards matching configuration
    func fetchQueueCards(currentDate: Date, configuration: ConfigurationAppIntent) throws -> [Card] {
        let fetchDescriptor = FetchDescriptor<Card>(
//            sortBy: [
//                SortDescriptor(\Card.nextTimeInQueue, order: .forward),
//            ]
        )
        let filteredCards = try context.fetch(fetchDescriptor).filter { card in
            guard card.isEnqueue(currentDate: currentDate) else { return false }
            if !configuration.showFolders.isEmpty {
                guard let folder = card.folder, configuration.showFolders.contains(where: { $0.id == folder.id }) else {
                    return false
                }
            }
            if !configuration.showCardType.isEmpty {
                guard configuration.showCardType.contains(card.cardType) else { return false }
            }
            return card.isEnqueue(currentDate: currentDate)
        }
        return filteredCards.sorted {
            ($0.priority.sortValue, $0.nextTimeInQueue) < ($1.priority.sortValue, $1.nextTimeInQueue)
        }
    }

    /// Fetches queued cards, the next card, and total number of cards matching the configuration.
    func fetchQueueCardsAndSummary(currentDate: Date, configuration: ConfigurationAppIntent) throws -> ([Card], Card?, Int) {
        let allCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        let nextCard = allCards.first
        let totalNumberOfCards = allCards.count
        return (allCards, nextCard, totalNumberOfCards)
    }

    func skipTopCard(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        // cardType has already been filtered by fetchQueueCards, so the first card matches the configuration
        guard let topCard = queueCards.first else { return }
        topCard.skip(at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func nextTopCard(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        // cardType has already been filtered by fetchQueueCards, so the first card matches the configuration
        guard let topCard = queueCards.first else { return }
        topCard.next(at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func completeTopCard(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let todoCard = queueCards.first(where: { $0.cardType == CardType.todo }) else { return }
        todoCard.markAsComplete(at: currentDate)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: "TopNoteWidget")
    }

    func rateTopFlashcard(currentDate: Date, configuration: ConfigurationAppIntent, rating: Int) async throws {
        let queueCards = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let flashcard = queueCards.first(where: { $0.cardType == .flashcard }) else { return }
        let ratingTypes = RatingType.allCases
        guard rating >= 0 && rating < ratingTypes.count else { return }
        let ratingType = ratingTypes[rating]
        flashcard.submitFlashcardRating(ratingType, at: currentDate)
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

