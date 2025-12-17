//
//  CardEntity.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import Foundation
import WidgetKit
import SwiftUI
import AppIntents
import UIKit
import os.log

struct CardEntity: AppEntity {
    var id: UUID
    var createdAt: Date
    var cardTypeRaw: String
    var content: String
    var answer: String?
    var isRecurring: Bool
    var skipCount: Int
    var seenCount: Int
    var repeatInterval: Int
    var nextTimeInQueue: Date
    var folder: Folder?
    var isArchived: Bool
    var answerRevealed: Bool
    var skipEnabled: Bool
    var tags: [String]?

    var cardType: CardType {
        CardType(rawValue: cardTypeRaw) ?? .note
    }

    static var defaultQuery = CardEntityQuery()

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Cards", table: "AppIntents")
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: content)
    }
}

struct CardEntry: TimelineEntry {
    let date: Date
    let card: CardEntity
    let queueCardCount: Int
    let totalNumberOfCards: Int
    let nextCardForQueue: CardEntity?
    let nextUpdateDate: Date

    let selectedCardTypes: [CardType]
    let selectedFolders: [Folder]

    // Widget-instance state tracking
    let widgetIdentifier: String
}

extension CardEntity {
    init(card: Card) {
        self.id = card.id
        self.createdAt = card.createdAt
        self.cardTypeRaw = card.cardType.rawValue
        self.content = card.displayContent
        self.answer = card.displayAnswer
        self.isRecurring = card.isRecurring
        self.skipCount = card.skipCount
        self.seenCount = card.seenCount
        self.repeatInterval = card.repeatInterval
        self.nextTimeInQueue = card.nextTimeInQueue
        self.folder = card.folder
        self.isArchived = card.isArchived
        self.answerRevealed = card.answerRevealed
        self.skipEnabled = card.skipEnabled
        self.tags = card.unwrappedTags.map(\.name)
    }
}
