//
//  AppIntent.swift
//  FlashCardWidget
//
//  Created by Zachary Sturman on 2/17/25.
//

import WidgetKit
import AppIntents
import SwiftData

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Top Note Widget"}
    static var description: IntentDescription { "Displays a card from your collection." }


    @Parameter(title: "Show Flashcards", default: true)
    var showFlashCards: Bool
    
    @Parameter(title: "Show Cards with no type", default: true)
    var showNoCardType: Bool

    enum CardType: String, AppEnum {
        case flashCard = "Flash Card"
        case noType = "No Type"

        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            "Card Type"
        }

        static var caseDisplayRepresentations: [CardType: DisplayRepresentation] {
            [
                .flashCard: "Flash Card",
                .noType: "No Type"
            ]
        }
    }
}

// FLASHGCARD
struct SubmitFlashcardRatingTypeIntent: AppIntent {
    static var title: LocalizedStringResource = "Difficulty Rating"

    @Parameter(title: "Selected Rating")
    var selectedRating: Int

    init(selectedRating: Int) {
        self.selectedRating = selectedRating
    }

    init() {}

    func perform() async throws -> some IntentResult {

        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a skip action.
        try await queueManager.submitFlashcardRating(currentDate: currentDate, configuration: ConfigurationAppIntent(), rating: selectedRating)
        
        return .result()
    }
}



struct ShowFlashcardBackIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Back"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a skip action.
        try await queueManager.showFlashcardBack(currentDate: currentDate, configuration: ConfigurationAppIntent())

        return .result()
    }
}






struct SkipCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Card"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a skip action.
        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), isSkip: true)
        return .result()
    }
}


struct NextCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Card"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a "next" action (without incrementing skipCount).
        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), isSkip: false)
        return .result()
    }
}

struct ArchiveCardIntent: AppIntent {
    static var title: LocalizedStringResource = "Archive Card"
    
    func perform() async throws -> some IntentResult {
        let container = try ModelContainer(for: Card.self)
        let context = ModelContext(container)
        let queueManager = QueueManager(context: context)
        let currentDate = Date()
        
        // Remove the top card as a "next" action (without incrementing skipCount).
        try await queueManager.removeTopCard(currentDate: currentDate, configuration: ConfigurationAppIntent(), isSkip: false, toArchive: true)
        return .result()
    }
}
