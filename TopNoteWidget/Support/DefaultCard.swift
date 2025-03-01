//
//  DefaultCard.swift
//  TopNoteWidgetExtension
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftData


func placeholderCardEntry() -> CardEntry {
    return CardEntry(
        date: Date(),
        card: Card(
            createdAt: Date(),
            cardType: .none,
            priorityTypeRaw: .none,
            content: "Nothing to see here",
            seenCount: 0,
            spacedTimeFrame: 0,
            nextTimeInQueue: Date()
        ),
        queueCardCount: 1,
        totalNumberOfCards: 1,
        nextCardForQueue: nil,
        nextUpdateDate: Date()
    )
}

func sampleCardEntry() -> CardEntry {
    let sampleCard = Card(
        createdAt: Date(),
        cardType: .none,
        priorityTypeRaw: .none,
        
        content: "Nothing to see here",
        seenCount: 0,
        spacedTimeFrame: 0,
        nextTimeInQueue: Date()
    )
    return CardEntry(date: Date(), card: sampleCard,                 queueCardCount: 1,
                     totalNumberOfCards: 1, nextCardForQueue: nil, nextUpdateDate: Date())
}

func allCaughtUpCardEntry(currentDate: Date, totalNumberOfCards: Int, nextCardForQueue: Card?) -> CardEntry {
    return CardEntry(
        date: currentDate,
        card: Card(
            createdAt: Date(),
            cardType: .none,
            priorityTypeRaw: .none,
            content: "All Caught Up",
            seenCount: 0,
            spacedTimeFrame: 0,
            nextTimeInQueue: Date()
        ),
        queueCardCount: 0,
        totalNumberOfCards: totalNumberOfCards,
        nextCardForQueue: nextCardForQueue,
        nextUpdateDate: Date()
    )
}

func errorCardEntry() -> CardEntry {
    return CardEntry(
        date: Date(),
        card: Card(
            createdAt: Date(),
            cardType: .none,
            priorityTypeRaw: .none,
            content: "Error",
            seenCount: 0,
            spacedTimeFrame: 0,
            nextTimeInQueue: Date()
        ),
        queueCardCount: 0,
        totalNumberOfCards: 0,
        nextCardForQueue: nil,
        nextUpdateDate: Date()
    )
}
func getSampleFlashCard(hasBeenFlipped: Bool) -> Card {
    // Sample card for Flash Card type
    let sampleFlashCard: Card = {
        return Card(
            createdAt: Date(),
            cardType: .flashCard,
            priorityTypeRaw: .med,
            content: "What is the capital of France?",
            isEssential: true,
            skipCount: 0,
            seenCount: 1,
            timeOnTop: Date(),
            timeInQueue: Date(),
            spacedTimeFrame: 240,
            dynamicTimeframe: true,
            nextTimeInQueue: Date().addingTimeInterval(3600),
            lastRemovedFromQueue: nil,
            folder: nil,
            tags: [],
            back: "Paris",
            rating: [],
            archived: false,
            hasBeenFlipped: hasBeenFlipped
        )
    }()
    
    return sampleFlashCard
}

func getSampleNoTypeCard() -> Card {
    // Sample card for None type (plain content)
    let sampleNoCardCard: Card = {
        return Card(
            createdAt: Date(),
            cardType: .none,
            priorityTypeRaw: .none,
            content: "Just some plain content without a specific card type.",
            isEssential: false,
            skipCount: 0,
            seenCount: 1,
            timeOnTop: Date(),
            timeInQueue: Date(),
            spacedTimeFrame: 240,
            dynamicTimeframe: true,
            nextTimeInQueue: Date().addingTimeInterval(3600),
            lastRemovedFromQueue: nil,
            folder: nil,
            tags: [],
            back: nil,
            rating: [],
            archived: false,
            hasBeenFlipped: false
        )
    }()
    
    return sampleNoCardCard
    
}
