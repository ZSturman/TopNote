//
//  DefaultCard.swift
//  TopNoteWidgetExtension
//
//  Created by Zachary Sturman on 2/25/25.
//

import Foundation
import SwiftData


func placeholderCardEntry() -> CardEntry {
    let dummyCard = Card.makeDummy()
    let dummyCardEntity = CardEntity(
        id: UUID(),
        createdAt: dummyCard.createdAt,
        cardTypeRaw: dummyCard.cardType.rawValue,
        content: dummyCard.content,
        answer: dummyCard.answer,
        isRecurring: dummyCard.isRecurring,
        skipCount: dummyCard.skipCount,
        seenCount: dummyCard.seenCount,
        repeatInterval: dummyCard.repeatInterval,
        nextTimeInQueue: dummyCard.nextTimeInQueue,
        folder: dummyCard.folder,
        isArchived: dummyCard.isArchived,
        answerRevealed: false,
        skipEnabled: true,
        tags: nil
    )
    return CardEntry(
        date: Date(),
        card: dummyCardEntity,
        queueCardCount: 1,
        totalNumberOfCards: 10,
        nextCardForQueue: dummyCardEntity,
        nextUpdateDate: Date().addingTimeInterval(300),
        selectedCardTypes: [.note],
        selectedFolders: []
    )
}

func sampleCardEntry() -> CardEntry {
    let sampleCard = Card.makeDummy()
    let sampleCardEntity = CardEntity(
        id: UUID(),
        createdAt: sampleCard.createdAt,
        cardTypeRaw: sampleCard.cardType.rawValue,
        content: sampleCard.content,
        answer: sampleCard.answer,
        isRecurring: sampleCard.isRecurring,
        skipCount: sampleCard.skipCount,
        seenCount: sampleCard.seenCount,
        repeatInterval: sampleCard.repeatInterval,
        nextTimeInQueue: sampleCard.nextTimeInQueue,
        folder: sampleCard.folder,
        isArchived: sampleCard.isArchived,
        answerRevealed: false,
        skipEnabled: true,
        tags: nil
    )
    return CardEntry(
        date: Date(),
        card: sampleCardEntity,
        queueCardCount: 3,
        totalNumberOfCards: 10,
        nextCardForQueue: sampleCardEntity,
        nextUpdateDate: Date().addingTimeInterval(300),
        selectedCardTypes: [.note],
        selectedFolders: []
    )
}

func allCaughtUpCardEntry(currentDate: Date, totalNumberOfCards: Int, nextCardForQueue: Card?) -> CardEntry {
    let card = Card(
        createdAt: Date(),
        cardType: .todo,
        priorityTypeRaw: .none,
        //priorityTypeRaw: .none,
        content: "All Caught Up",
        seenCount: 0,
        nextTimeInQueue: Date()
    )
    let cardEntity = CardEntity(
        id: UUID(),
        createdAt: card.createdAt,
        cardTypeRaw: card.cardType.rawValue,
        content: card.content,
        answer: card.answer,
        isRecurring: card.isRecurring,
        skipCount: card.skipCount,
        seenCount: card.seenCount,
        repeatInterval: card.repeatInterval,
        nextTimeInQueue: card.nextTimeInQueue,
        folder: card.folder,
        isArchived: card.isArchived,
        answerRevealed: false,
        skipEnabled: true,
        tags: nil
    )
    let nextCardForQueueEntity: CardEntity? = {
        guard let nextCard = nextCardForQueue else { return nil }
        return CardEntity(
            id: UUID(),
            createdAt: nextCard.createdAt,
            cardTypeRaw: nextCard.cardType.rawValue,
            content: nextCard.content,
            answer: nextCard.answer,
            isRecurring: nextCard.isRecurring,
            skipCount: nextCard.skipCount,
            seenCount: nextCard.seenCount,
            repeatInterval: nextCard.repeatInterval,
            nextTimeInQueue: nextCard.nextTimeInQueue,
            folder: nextCard.folder,
            isArchived: nextCard.isArchived,
            answerRevealed: false,
            skipEnabled: true,
            tags: nil
        )
    }()
    return CardEntry(
        date: currentDate,
        card: cardEntity,
        queueCardCount: 0,
        totalNumberOfCards: totalNumberOfCards,
        nextCardForQueue: nextCardForQueueEntity,
        nextUpdateDate: Date(),
        selectedCardTypes: [],
        selectedFolders: []
    )
}

func allCaughtUpCardEntry(currentDate: Date, totalNumberOfCards: Int, nextCardForQueue: Card?, configuredTypes: [CardType]) -> CardEntry {
    // Create a placeholder Card with content as the message
    let message = allCaughtUpMessage(for: configuredTypes)

    let placeholderCard = Card(
        createdAt: currentDate,
        cardType: configuredTypes.first ?? .note,
        priorityTypeRaw: .none,
        content: message,
        isRecurring: false,
        skipCount: 0,
        seenCount: 0,
        repeatInterval: 240,
        //isDynamic: true,
        nextTimeInQueue: currentDate.addingTimeInterval(60),
        folder: nil,
        tags: [],
        answer: "",
        rating: [],
        isArchived: false,
        //answerRevealed: false,
        skipPolicy: .none,
        ratingEasyPolicy: .mild,
        ratingMedPolicy: .none,
        ratingHardPolicy: .aggressive,
        isComplete: false
    )

    let placeholderCardEntity = CardEntity(
        id: UUID(),
        createdAt: placeholderCard.createdAt,
        cardTypeRaw: placeholderCard.cardType.rawValue,
        content: placeholderCard.content,
        answer: placeholderCard.answer,
        isRecurring: placeholderCard.isRecurring,
        skipCount: placeholderCard.skipCount,
        seenCount: placeholderCard.seenCount,
        repeatInterval: placeholderCard.repeatInterval,
        nextTimeInQueue: placeholderCard.nextTimeInQueue,
        folder: placeholderCard.folder,
        isArchived: placeholderCard.isArchived,
        answerRevealed: false,
        skipEnabled: true,
        tags: nil
    )
    let nextCardForQueueEntity: CardEntity? = {
        guard let nextCard = nextCardForQueue else { return nil }
        return CardEntity(
            id: UUID(),
            createdAt: nextCard.createdAt,
            cardTypeRaw: nextCard.cardType.rawValue,
            content: nextCard.content,
            answer: nextCard.answer,
            isRecurring: nextCard.isRecurring,
            skipCount: nextCard.skipCount,
            seenCount: nextCard.seenCount,
            repeatInterval: nextCard.repeatInterval,
            nextTimeInQueue: nextCard.nextTimeInQueue,
            folder: nextCard.folder,
            isArchived: nextCard.isArchived,
            answerRevealed: false,
            skipEnabled: true,
            tags: nil
        )
    }()
    return CardEntry(
        date: currentDate,
        card: placeholderCardEntity,
        queueCardCount: 0,
        totalNumberOfCards: totalNumberOfCards,
        nextCardForQueue: nextCardForQueueEntity,
        nextUpdateDate: currentDate.addingTimeInterval(60),
        selectedCardTypes: [],
        selectedFolders: []
    )
}

func errorCardEntry() -> CardEntry {
    let dummyCard = Card.makeDummy()
    let dummyCardEntity = CardEntity(
        id: UUID(),
        createdAt: dummyCard.createdAt,
        cardTypeRaw: dummyCard.cardType.rawValue,
        content: dummyCard.content,
        answer: dummyCard.answer,
        isRecurring: dummyCard.isRecurring,
        skipCount: dummyCard.skipCount,
        seenCount: dummyCard.seenCount,
        repeatInterval: dummyCard.repeatInterval,
        nextTimeInQueue: dummyCard.nextTimeInQueue,
        folder: dummyCard.folder,
        isArchived: dummyCard.isArchived,
        answerRevealed: false,
        skipEnabled: true,
        tags: nil
    )
    return CardEntry(
        date: Date(),
        card: dummyCardEntity,
        queueCardCount: 0,
        totalNumberOfCards: 0,
        nextCardForQueue: nil,
        nextUpdateDate: Date().addingTimeInterval(3600),
        selectedCardTypes: [],
        selectedFolders: []
    )
}

func getSampleFlashCard(answerRevealed: Bool) -> Card {
    // Sample card for Flash Card type
    let sampleFlashCard: Card = {
        return Card(
            createdAt: Date(),
            cardType: .flashcard,
            priorityTypeRaw: .none,
            //priorityTypeRaw: .med,
            content: "What is the capital of France?",
            isRecurring: true,
            skipCount: 0,
            seenCount: 1,
            repeatInterval: 240,
            //isDynamic: true,
            nextTimeInQueue: Date().addingTimeInterval(3600),
            folder: nil,
            tags: [],
            answer: "Paris",
            rating: [],
            isArchived: false
            //answerRevealed: answerRevealed
        )
    }()
    
    return sampleFlashCard
}

func getSampleNoTypeCard() -> Card {
    // Sample card for None type (plain content)
    let sampleNoCardCard: Card = {
        return Card(
            createdAt: Date(),
            cardType: .todo,
            priorityTypeRaw: .none,
            //priorityTypeRaw: .none,
            content: "Just some plain content without a specific card type.",
            isRecurring: false,
            skipCount: 0,
            seenCount: 1,
            repeatInterval: 240,
            //isDynamic: true,
            nextTimeInQueue: Date().addingTimeInterval(3600),
            folder: nil,
            tags: [],
            answer: nil,
            rating: [],
            isArchived: false
            //answerRevealed: false
        )
    }()
    
    return sampleNoCardCard
    
}


// Helper function to create an "All caught up" message based on card types
func allCaughtUpMessage(for types: [CardType], folders: [Folder]? = nil) -> String {
    let uniqueTypes = Set(types)
    // If folders are provided, we can also include them in the message
    if let folders = folders, !folders.isEmpty {
        let folderNames = folders.map { $0.name }.joined(separator: ", ")
        switch uniqueTypes.count {
        case 0:
            return "All caught up in \(folderNames)!"
        case 1:
            if let type = uniqueTypes.first {
                switch type {
                case .note:
                    return "All notes in \(folderNames) caught up!"
                case .flashcard:
                    return "All flashcards in \(folderNames) caught up!"
                case .todo:
                    return "All todos in \(folderNames) caught up!"
                }
            }
            return "All caught up in \(folderNames)!"
        case 2:
            if uniqueTypes.contains(.note) && uniqueTypes.contains(.todo) {
                return "All notes and todos in \(folderNames) caught up!"
            } else if uniqueTypes.contains(.note) && uniqueTypes.contains(.flashcard) {
                return "All notes and flashcards in \(folderNames) caught up!"
            } else if uniqueTypes.contains(.flashcard) && uniqueTypes.contains(.todo) {
                return "All flashcards and todos in \(folderNames) caught up!"
            }
            return "All caught up in \(folderNames)!"
        default:
            return "All caught up in \(folderNames)!"
        }
    } else {
        // No folders specified, use the original logic
        switch uniqueTypes.count {
        case 0:
            return "All caught up!"
        case 1:
            if let type = uniqueTypes.first {
                switch type {
                case .note:
                    return "All notes caught up!"
                case .flashcard:
                    return "All flashcards caught up!"
                case .todo:
                    return "All todos caught up!"
                }
            }
            return "All caught up!"
        case 2:
            if uniqueTypes.contains(.note) && uniqueTypes.contains(.todo) {
                return "All notes and todos caught up!"
            } else if uniqueTypes.contains(.note) && uniqueTypes.contains(.flashcard) {
                return "All notes and flashcards caught up!"
            } else if uniqueTypes.contains(.flashcard) && uniqueTypes.contains(.todo) {
                return "All flashcards and todos caught up!"
            }
            return "All caught up!"
        default:
            return "All caught up!"
        }
    }
}
