//
//  Card+Extensions.swift
//  TopNote
//
//  Created by Zachary Sturman on 3/4/25.
//

import Foundation
import WidgetKit

extension Card {
    
    // MARK: - Content Update Methods
    
    /// Updates the main content of the card.
    func updateCardContent(content: String) async throws {
        self.content = content
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Updates the back content of the card.
    func updateCardBackContent(backContent: String) async throws {
        self.back = backContent
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Priority and Queue Methods
    
    /// Updates the priority value of the card.
    func updatePriorityValue(priority: PriorityType) async throws {
        self.priority = priority
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Adds the card to the queue.
    func addCardToQueue(currentDate: Date) async throws {
        self.nextTimeInQueue = currentDate
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Adjusts the spaced timeframe using a multiplier.
    func updateSpacedTimeframe(multiplier: Double) async throws {
        let newTimeframe: Int = Int(Double(self.spacedTimeFrame) * multiplier)
        
        if newTimeframe < 1 {
            self.spacedTimeFrame = 1
        } else if newTimeframe > 8760 {
            self.spacedTimeFrame = 8760
        } else {
            self.spacedTimeFrame = newTimeframe
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Submits a flashcard rating and, if enabled, dynamically adjusts the spaced timeframe.
    func submitFlashcardRating(currentDate: Date, rating: RatingType) async throws {
        if self.dynamicTimeframe {
            switch rating {
            case .easy:
                try await updateSpacedTimeframe(multiplier: 1.5)
            case .good:
                try await updateSpacedTimeframe(multiplier: 1)
            case .hard:
                try await updateSpacedTimeframe(multiplier: 0.5)
            }
        }
        self.rating.append([rating: currentDate])
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Updates the next queue date based on the current date.
    func updateNextInQueueDate(at currentDate: Date) async throws {
        if let newNextDate = Calendar.current.date(byAdding: .hour, value: self.spacedTimeFrame, to: currentDate) {
            self.nextTimeInQueue = newNextDate
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Manually updates the spaced timeframe and adjusts the next queue date if applicable.
    func manuallyUpdateSpacedTimeFrame(newValue: Int) async throws {
        self.spacedTimeFrame = newValue
        
        if self.isEnqueue(currentDate: Date()) { return }
        if let newNextDate = Calendar.current.date(byAdding: .hour, value: newValue, to: self.lastRemovedFromQueue ?? self.createdAt) {
            self.nextTimeInQueue = newNextDate
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Queue Removal and Card State Methods
    
    /// Removes the card from the queue and optionally archives it.
    func removeFromQueue(at removalDate: Date, isSkip: Bool, toArchive: Bool = false) async throws {
        if toArchive {
            self.nextTimeInQueue = .distantFuture
        } else if isSkip {
            self.skipCount += 1
            try await updateSpacedTimeframe(multiplier: 0.5)
        }
        
        // Record removal and reset relevant properties.
        self.lastRemovedFromQueue = removalDate
        self.timeOnTop = nil
        self.timeInQueue = nil
        self.archived = toArchive
        self.hasBeenFlipped = false
        
        if !toArchive {
            try await updateNextInQueueDate(at: removalDate)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Marks the card as flipped.
    func flipCard() async throws {
        self.hasBeenFlipped = true
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Unarchives the card.
    func removeCardFromArchive() async throws {
        self.archived = false
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Toggles whether the card is marked as essential.
    func toggleIsEssential() async throws {
        self.isEssential.toggle()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Toggles the dynamic timeframe feature.
    func toggleIsDynamic() async throws {
        self.dynamicTimeframe.toggle()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Updates the card type.
    func updateCardType(cardType: CardType) async throws {
        self.cardType = cardType
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Folder Management
    
    /// Moves the card to a specified folder.
    func moveToFolder(folder: Folder?) async throws {
        self.folder = folder
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Rating Aggregation
    
    /// Aggregates the rating events from the rating history.
    var ratingEvents: [RatingEvent] {
        rating.compactMap { dict in
            if let (rating, date) = dict.first {
                return RatingEvent(rating: rating, date: date)
            }
            return nil
        }
    }
    
    /// Computes counts for each rating type.
    var ratingCounts: [RatingCount] {
        let grouped = Dictionary(grouping: ratingEvents, by: { $0.rating })
        return grouped.map { RatingCount(rating: $0.key, count: $0.value.count) }
            .sorted { $0.rating.rawValue < $1.rating.rawValue }
    }
}
