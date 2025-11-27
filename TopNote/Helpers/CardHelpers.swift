//
//  CardHelpers.swift
//  TopNote
//
//  Created by Zachary Sturman on 8/9/25.
//

import Foundation
import SwiftData

/// Duplicates a Card and inserts the copy into the provided context.
/// - Parameters:
///   - card: The Card to duplicate.
///   - context: The ModelContext to insert the new Card into.
/// - Returns: The duplicated Card instance.
@discardableResult
func duplicateCard(_ card: Card, in context: ModelContext) -> Card {
    let now = Date()
    let duplicate = Card(
        createdAt: now,
        cardType: card.cardType,
        priorityTypeRaw: card.priority,
        content: card.content,
        isRecurring: card.isRecurring,
        skipCount: card.skipCount,
        seenCount: card.seenCount,
        repeatInterval: card.repeatInterval,
        //isDynamic: card.isDynamic,
        nextTimeInQueue: card.nextTimeInQueue,
        folder: card.folder,
        tags: card.unwrappedTags,
        answer: card.answer,
        rating: card.rating,
        isArchived: card.isArchived,
        //answerRevealed: card.answerRevealed,
        skipPolicy: card.skipPolicy,
        ratingEasyPolicy: card.ratingEasyPolicy,
        ratingMedPolicy: card.ratingMedPolicy,
        ratingHardPolicy: card.ratingHardPolicy,
        isComplete: card.isComplete
    )
    context.insert(duplicate)
    return duplicate
}

/// Creates and inserts a new Card into the context.
@discardableResult
func createCard(
    in context: ModelContext,
    cardType: CardType = .todo,
    content: String = "",
    answer: String? = nil,
    folder: Folder? = nil,
    tags: [CardTag] = [],
    isRecurring: Bool = false
) -> Card {
    let now = Date()
    let card = Card(
        createdAt: now,
        cardType: cardType,
        priorityTypeRaw: .none,
        content: content,
        isRecurring: isRecurring,
        skipCount: 0,
        seenCount: 0,
        repeatInterval: 240,
        //isDynamic: true,
        nextTimeInQueue: now,
        folder: folder,
        tags: tags,
        answer: answer,
        rating: [],
        isArchived: false,
        //answerRevealed: false,
        skipPolicy: .none,
        ratingEasyPolicy: .mild,
        ratingMedPolicy: .none,
        ratingHardPolicy: .aggressive
    )
    context.insert(card)
    return card
}
