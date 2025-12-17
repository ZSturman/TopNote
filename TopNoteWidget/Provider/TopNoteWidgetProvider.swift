//
//  TopNoteWidgetProvider.swift
//  TopNote
//
//  Created by Zachary Sturman on 12/13/25.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        placeholderCardEntry(widgetIdentifier: "placeholder")
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> CardEntry {
        sampleCardEntry(widgetIdentifier: "snapshot")
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<CardEntry> {
        let currentDate = Date()

        // Basic per-instance widget identifier
        let widgetIdentifier = "\(context.family.rawValue)_\(abs(context.displaySize.width.hashValue ^ context.displaySize.height.hashValue))"

        if configuration.showCardType.isEmpty {
            let entry = noCardTypesSelectedEntry(
                currentDate: currentDate,
                selectedCardTypes: configuration.showCardType,
                selectedFolders: configuration.showFolders,
                widgetIdentifier: widgetIdentifier
            )
            return Timeline(entries: [entry], policy: .never)
        }

        // Use the shared container that's configured with App Group
        let container = sharedModelContainer

        let modelContext = ModelContext(container)
        let queueManager = QueueManager(context: modelContext)

        do {
            let (cardsInQueue, nextCardForQueue, totalNumberOfCards) =
                try queueManager.fetchQueueCardsAndSummary(
                    currentDate: currentDate,
                    configuration: configuration
                )

            let cardsInQueueEntities = cardsInQueue.map {
                CardEntity(card: $0)
            }
            let nextCardEntity = nextCardForQueue.map {
                CardEntity(card: $0)
            }

            let updateDate = nextCardEntity?.nextTimeInQueue ?? currentDate.addingTimeInterval(60)

            if cardsInQueueEntities.isEmpty {
                let entry = allCaughtUpCardEntry(
                    currentDate: currentDate,
                    totalNumberOfCards: totalNumberOfCards,
                    nextCardForQueue: nextCardEntity,
                    configuredTypes: configuration.showCardType,
                    selectedCardTypes: configuration.showCardType,
                    selectedFolders: configuration.showFolders,
                    widgetIdentifier: widgetIdentifier
                )
                return Timeline(entries: [entry], policy: .after(updateDate))
            }

            // Top card state reset if needed
            if let topCard = cardsInQueueEntities.first {
                WidgetStateManager.shared.checkAndResetIfNeeded(
                    widgetID: widgetIdentifier,
                    currentCardID: topCard.id
                )

                let entry = CardEntry(
                    date: currentDate,
                    card: topCard,
                    queueCardCount: cardsInQueueEntities.count,
                    totalNumberOfCards: totalNumberOfCards,
                    nextCardForQueue: nextCardEntity,
                    nextUpdateDate: updateDate,
                    selectedCardTypes: configuration.showCardType,
                    selectedFolders: configuration.showFolders,
                    widgetIdentifier: widgetIdentifier
                )

                let nextRefresh = Calendar.current.date(
                    byAdding: .minute,
                    value: 5,
                    to: currentDate
                ) ?? Date()

                return Timeline(entries: [entry], policy: .after(nextRefresh))
            } else {
                let entry = errorCardEntry(widgetIdentifier: widgetIdentifier)
                return Timeline(entries: [entry], policy: .never)
            }
        } catch {
            print("Error updating queue: \(error)")
            let entry = errorCardEntry(widgetIdentifier: widgetIdentifier)
            return Timeline(entries: [entry], policy: .never)
        }
    }
}

// MARK: - Entry helpers

func noCardTypesSelectedEntry(
    currentDate: Date,
    selectedCardTypes: [CardType],
    selectedFolders: [Folder],
    widgetIdentifier: String
) -> CardEntry {
    let dummyCardEntity = makeDummyCardEntity()

    return CardEntry(
        date: currentDate,
        card: dummyCardEntity,
        queueCardCount: 0,
        totalNumberOfCards: 0,
        nextCardForQueue: nil,
        nextUpdateDate: currentDate.addingTimeInterval(3600),
        selectedCardTypes: selectedCardTypes,
        selectedFolders: selectedFolders,
        widgetIdentifier: widgetIdentifier
    )
}

func allCaughtUpCardEntry(
    currentDate: Date,
    totalNumberOfCards: Int,
    nextCardForQueue: CardEntity?,
    configuredTypes: [CardType],
    selectedCardTypes: [CardType],
    selectedFolders: [Folder],
    widgetIdentifier: String
) -> CardEntry {
    let dummyCardEntity = makeDummyCardEntity()

    return CardEntry(
        date: currentDate,
        card: dummyCardEntity,
        queueCardCount: 0,
        totalNumberOfCards: totalNumberOfCards,
        nextCardForQueue: nextCardForQueue,
        nextUpdateDate: nextCardForQueue?.nextTimeInQueue ?? currentDate.addingTimeInterval(3600),
        selectedCardTypes: selectedCardTypes,
        selectedFolders: selectedFolders,
        widgetIdentifier: widgetIdentifier
    )
}


private func makeDummyCardEntity() -> CardEntity {
    return CardEntity(
        id: UUID(),
        createdAt: Date(),
        cardTypeRaw: "note",
        content: "",
        answer: nil,
        isRecurring: false,
        skipCount: 0,
        seenCount: 0,
        repeatInterval: 0,
        nextTimeInQueue: Date().addingTimeInterval(3600),
        folder: nil,
        isArchived: false,
        answerRevealed: false,
        skipEnabled: true,
        tags: nil,
        // widgetTextHidden: false,
    )
}
