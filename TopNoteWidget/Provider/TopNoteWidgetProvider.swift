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

        let widgetImageMaxSize: CGFloat = {
            switch context.family {
            case .systemSmall:
                return 300
            case .systemMedium:
                return 600
            case .systemLarge:
                return 900
            case .systemExtraLarge:
                return 1100
            case .accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner:
                return 300
            @unknown default:
                return 600
            }
        }()

        if configuration.showCardType.isEmpty {
            let entry = noCardTypesSelectedEntry(
                currentDate: currentDate,
                selectedCardTypes: configuration.showCardType,
                selectedFolders: configuration.showFolders,
                widgetIdentifier: widgetIdentifier
            )
            return Timeline(entries: [entry], policy: .never)
        }

        guard let container = try? ModelContainer(for: Card.self) else {
            return Timeline(entries: [], policy: .never)
        }

        let modelContext = ModelContext(container)
        let queueManager = QueueManager(context: modelContext)

        do {
            let (cardsInQueue, nextCardForQueue, totalNumberOfCards) =
                try queueManager.fetchQueueCardsAndSummary(
                    currentDate: currentDate,
                    configuration: configuration
                )

            let cardsInQueueEntities = cardsInQueue.map {
                CardEntity(card: $0, widgetImageMaxSize: widgetImageMaxSize)
            }
            let nextCardEntity = nextCardForQueue.map {
                CardEntity(card: $0, widgetImageMaxSize: widgetImageMaxSize)
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
    let dummyCard = Card.makeDummy()
    let dummyCardEntity = CardEntity(
        id: dummyCard.id,
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
        answerRevealed: dummyCard.answerRevealed,
        skipEnabled: dummyCard.skipEnabled,
        tags: nil,
        widgetTextHidden: dummyCard.widgetTextHidden,
        contentImageData: nil,
        answerImageData: nil
    )

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
    let dummyCard = Card.makeDummy()
    let dummyCardEntity = CardEntity(
        id: dummyCard.id,
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
        answerRevealed: dummyCard.answerRevealed,
        skipEnabled: dummyCard.skipEnabled,
        tags: nil,
        widgetTextHidden: dummyCard.widgetTextHidden,
        contentImageData: nil,
        answerImageData: nil
    )

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

//// Placeholder / snapshot helpers can be implemented as needed
//func placeholderCardEntry(widgetIdentifier: String) -> CardEntry {
//    let dummy = Card.makeDummy()
//    let dummyEntity = CardEntity(
//        id: dummy.id,
//        createdAt: dummy.createdAt,
//        cardTypeRaw: dummy.cardType.rawValue,
//        content: "Sample card content",
//        answer: "Sample answer",
//        isRecurring: false,
//        skipCount: 0,
//        seenCount: 0,
//        repeatInterval: 0,
//        nextTimeInQueue: Date(),
//        folder: nil,
//        isArchived: false,
//        answerRevealed: false,
//        skipEnabled: true,
//        tags: nil,
//        widgetTextHidden: false,
//        contentImageData: nil,
//        answerImageData: nil
//    )
//
//    return CardEntry(
//        date: Date(),
//        card: dummyEntity,
//        queueCardCount: 1,
//        totalNumberOfCards: 1,
//        nextCardForQueue: nil,
//        nextUpdateDate: Date().addingTimeInterval(3600),
//        selectedCardTypes: [.note],
//        selectedFolders: [],
//        widgetIdentifier: widgetIdentifier
//    )
//}
//
//func sampleCardEntry(widgetIdentifier: String) -> CardEntry {
//    placeholderCardEntry(widgetIdentifier: widgetIdentifier)
//}
//
//func errorCardEntry(widgetIdentifier: String) -> CardEntry {
//    let dummy = Card.makeDummy()
//    let dummyEntity = CardEntity(
//        id: dummy.id,
//        createdAt: dummy.createdAt,
//        cardTypeRaw: dummy.cardType.rawValue,
//        content: "Unable to load cards.",
//        answer: nil,
//        isRecurring: false,
//        skipCount: 0,
//        seenCount: 0,
//        repeatInterval: 0,
//        nextTimeInQueue: Date(),
//        folder: nil,
//        isArchived: false,
//        answerRevealed: false,
//        skipEnabled: false,
//        tags: nil,
//        widgetTextHidden: false,
//        contentImageData: nil,
//        answerImageData: nil
//    )
//
//    return CardEntry(
//        date: Date(),
//        card: dummyEntity,
//        queueCardCount: 0,
//        totalNumberOfCards: 0,
//        nextCardForQueue: nil,
//        nextUpdateDate: Date().addingTimeInterval(3600),
//        selectedCardTypes: [],
//        selectedFolders: [],
//        widgetIdentifier: widgetIdentifier
//    )
//}
