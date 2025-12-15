//
//  CardEntityQuery.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import AppIntents
import SwiftData

struct CardEntityQuery: EntityQuery {
    let container = sharedModelContainer

    func entities(for identifiers: [CardEntity.ID]) async throws -> [CardEntity] {
        let context = ModelContext(container)

        let cards: [Card]
        if identifiers.isEmpty {
            cards = try context.fetch(FetchDescriptor<Card>())
        } else {
            let idSet = Set(identifiers)
            cards = try context.fetch(FetchDescriptor<Card>()).filter { idSet.contains($0.id) }
        }

        return cards.map { card in
            CardEntity(
                id: card.id,
                createdAt: card.createdAt,
                cardTypeRaw: card.cardTypeRaw,
                content: card.content,
                answer: card.answer,
                isRecurring: card.isRecurring,
                skipCount: card.skipCount,
                seenCount: card.seenCount,
                repeatInterval: card.repeatInterval,
                nextTimeInQueue: card.nextTimeInQueue,
                folder: card.folder,
                isArchived: card.isArchived,
                answerRevealed: card.answerRevealed,
                skipEnabled: card.skipEnabled,
                tags: card.unwrappedTags.map(\.name),
                widgetTextHidden: card.widgetTextHidden,
                contentImageData: nil,
                answerImageData: nil
            )
        }
    }
}
