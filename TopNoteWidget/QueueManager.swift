//
//  CardQueueManager.swift
//  TopNoteWidgetExtension
//
//  Created by Zachary Sturman on 2/19/25.
//
import Foundation
import SwiftData
import WidgetKit

struct QueueManager {
    let context: ModelContext

    func fetchQueueCards(currentDate: Date, configuration: ConfigurationAppIntent) throws -> ([Card], Card?, Int) {
        let fetchDescriptor = FetchDescriptor<Card>(
            sortBy: [
                SortDescriptor(\.nextTimeInQueue, order: .reverse),
            ]
        )


        let allCards: [Card] = try context.fetch(fetchDescriptor).filter { card in
            // Exclude archived cards
            if card.archived {
                return false
            }
            // Filter by card type based on configuration
            switch card.cardType {
            case .flashCard:
                return configuration.showFlashCards
            case .none:
                return configuration.showNoCardType
            }
        }
        

        let nextCardNotInQueue = allCards.first { $0.nextTimeInQueue > currentDate }
        let filteredCards = allCards.filter { $0.nextTimeInQueue <= currentDate }
        let sortedQueueCards = filteredCards.sorted { lhs, rhs in
            let lhsTuple = (lhs.isEssential ? 0 : 1, sortOrder(for: lhs), lhs.timeInQueue ?? Date.distantFuture)
            let rhsTuple = (rhs.isEssential ? 0 : 1, sortOrder(for: rhs), rhs.timeInQueue ?? Date.distantFuture)
            return lhsTuple < rhsTuple
        }
        
        
        

        var didUpdate = false
        
        for (index, card) in sortedQueueCards.enumerated() {
            if card.timeInQueue == nil {
                card.timeInQueue = currentDate
                didUpdate = true
            }
            // For the first card in the list, also check timeOnTop.
            if index == 0, card.timeOnTop == nil {
                card.timeOnTop = currentDate
                card.seenCount += 1
                card.hasBeenFlipped = false
                didUpdate = true
            }
        }
        
        if didUpdate {
            try context.save()
        }
        
        return (sortedQueueCards, nextCardNotInQueue, allCards.count)
    }
    
    private func saveContext() async throws {
        try context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func sortOrder(for card: Card) -> Int {
        guard let priority = PriorityType(rawValue: card.priorityRaw) else {
            return 3 // Default to lowest priority if unknown
        }
        switch priority {
        case .high:
            return 0
        case .med:
            return 1
        case .low:
            return 2
        case .none:
            return 3
        }
    }
    

    func removeTopCard(currentDate: Date, configuration: ConfigurationAppIntent, isSkip: Bool = false, toArchive: Bool = false) async throws {
        let (queueCards, _, _) = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let topCard = queueCards.first else {
            print("No due cards available.")
            return
        }
        
        try await topCard.removeFromQueue(at: currentDate, isSkip: isSkip, toArchive: toArchive)
        
        try await saveContext()
    }
    
    
        
    func submitFlashcardRating(currentDate: Date, configuration: ConfigurationAppIntent, rating: Int) async throws {
        let (queueCards, _, _) = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let topCard = queueCards.first else {
            print("No due cards available.")
            return
        }
        
        try await topCard.flipCard()
        if topCard.cardType == .flashCard {
                // Map the selected rating to a RatingType.
                let ratingTypes = RatingType.allCases
                guard rating >= 0 && rating < ratingTypes.count else {
                    return
                }
                let ratingType = ratingTypes[rating]
                
                // Append the new rating with the current date.
                try await topCard.submitFlashcardRating(currentDate: currentDate, rating: ratingType)
            
        }
        
        try await topCard.removeFromQueue(at: currentDate, isSkip: false, toArchive: false)
        
        try await saveContext()
    }
    
    func showFlashcardBack(currentDate: Date, configuration: ConfigurationAppIntent) async throws {
        let (queueCards, _, _) = try fetchQueueCards(currentDate: currentDate, configuration: configuration)
        guard let topCard = queueCards.first else {
            print("No due cards available.")
            return
        }
        
        try await topCard.flipCard()
        try await saveContext()
    }
}
