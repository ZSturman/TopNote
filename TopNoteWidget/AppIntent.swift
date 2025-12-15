////
////  AppIntent.swift
////  FlashCardWidget
////
////  Created by Zachary Sturman on 2/17/25.
////
//
//import WidgetKit
//import AppIntents
//import SwiftData
//
// 
//
//struct ConfigurationAppIntent: WidgetConfigurationIntent {
//    static var title: LocalizedStringResource { "Top Note Widget"}
//    static var description: IntentDescription { "Displays a card from your collection." }
//
//
//    @Parameter(title: "Card Type", default: [.flashcard, .note, .todo])
//    var showCardType: [CardType]
//    
//    @Parameter(title: "Folders", default: [])
//    var showFolders: [Folder]
//    
//    /// Since AppIntents parameters require static default values and Folder represents user data,
//    /// the default is set to an empty array.
//    /// To provide all folders by default when no specific folders are selected,
//    /// use this computed property to get all folders dynamically.
//    var effectiveFolders: [Folder] {
//        get {
//            if showFolders.isEmpty {
//                // Fetch all folders dynamically.
//                // This is a placeholder; adapt the fetch logic as needed.
//                do {
//                    let container = try ModelContainer(for: Folder.self)
//                    let context = ModelContext(container)
//                    let allFolders = try context.fetch(FetchDescriptor<Folder>())
//                    return allFolders
//                } catch {
//                    // If fetching fails, return empty array as fallback.
//                    return []
//                }
//            } else {
//                return showFolders
//            }
//        }
//    }
//}
//
////let folders = fetchAllFolders() + [Folder.noFolder]
//
//// FLASHGCARD
//struct SubmitFlashcardRatingTypeIntent: AppIntent {
//    static var title: LocalizedStringResource = "Difficulty Rating"
//
//    @Parameter(title: "Selected Rating")
//    var selectedRating: Int
//    
//    @Parameter(title: "Card")
//    var card: CardEntity
//
//    init(selectedRating: Int, card: CardEntity) {
//        self.selectedRating = selectedRating
//        self.card = card
//    }
//
//    init() {}
//
//    func perform() async throws -> some IntentResult {
//        let container = sharedModelContainer
//        let context = ModelContext(container)
//        // Fetch Card model by id
//        let cardID = card.id
//        let fetchDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
//            card.id == cardID
//        })
//        let cards = try context.fetch(fetchDescriptor)
//        
//        if let cardModel = cards.first {
//            let currentDate = Date()
//            // Convert selectedRating (Int) to RatingType
//            let ratingCases = RatingType.allCases
//            if selectedRating >= 0 && selectedRating < ratingCases.count {
//                let ratingType = ratingCases[selectedRating]
//                cardModel.submitFlashcardRating(ratingType, at: currentDate)
//                try? context.save()
//                WidgetCenter.shared.reloadAllTimelines()
//            }
//        }
//        
//        return .result()
//    }
//}
//
//struct CompleteTodoIntent: AppIntent {
//    static var title: LocalizedStringResource = "Complete Todo"
//    
//    @Parameter(title: "Card")
//    var card: CardEntity
//    
//    init(card: CardEntity) {
//        self.card = card
//    }
//    
//    init() {}
//    
//    func perform() async throws -> some IntentResult {
//        let container = sharedModelContainer
//        let context = ModelContext(container)
//        let cardID = card.id
//        let fetchDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
//            card.id == cardID
//        })
//        let cards = try context.fetch(fetchDescriptor)
//        
//        if let cardModel = cards.first {
//            let currentDate = Date()
//            cardModel.markAsComplete(at: currentDate)
//            try? context.save()
//            WidgetCenter.shared.reloadAllTimelines()
//        }
//        
//        return .result()
//    }
//}
//
//struct CardEntityQuery: EntityQuery {
////    @Dependency(key: "ModelContainer")
////    private var modelContainer: ModelContainer
//    
//    let container = sharedModelContainer
//  
//
//    func entities(for identifiers: [CardEntity.ID]) async throws -> [CardEntity] {
//        let context = ModelContext(container)
//        let fetchDescriptor = FetchDescriptor<Card>()
//        let cards = try context.fetch(fetchDescriptor)
//        
//        // Map each Card to a CardEntity.
//        let entities = cards.map { card in
//            CardEntity(
//                id: card.id,
//                createdAt: card.createdAt,
//                cardTypeRaw: card.cardTypeRaw,
//                content: card.content,
//                answer: card.answer,
//                isRecurring: card.isRecurring,
//                skipCount: card.skipCount,
//                seenCount: card.seenCount,
//                repeatInterval: card.repeatInterval,
//                nextTimeInQueue: card.nextTimeInQueue,
//                folder: card.folder,
//                isArchived: card.isArchived,
//                answerRevealed: card.answerRevealed,
//                skipEnabled: card.skipEnabled,
//                tags: card.unwrappedTags.map(\.name),
//                widgetTextHidden: card.widgetTextHidden,
//                contentImageData: nil,
//                answerImageData: nil
//            )
//        }
//        
//        // If identifiers are provided, filter by them; otherwise, return all.
//        if identifiers.isEmpty {
//            return entities
//        } else {
//            return entities.filter { identifiers.contains($0.id) }
//        }
//    }
//}
//
//
//
//
//
//struct ShowFlashcardAnswer: AppIntent {
//    static var title: LocalizedStringResource = "Show Back"
//    
//    @Parameter(title: "Card")
//    var card: CardEntity
//    
//    @Parameter(title: "Widget ID")
//    var widgetID: String
//    
//    init(card: CardEntity, widgetID: String) {
//        self.card = card
//        self.widgetID = widgetID
//    }
//    
//    init() {}
//    
//    func perform() async throws -> some IntentResult {
//        // Update widget-level flip state instead of card state
//        WidgetStateManager.shared.setFlipped(true, widgetID: widgetID, cardID: card.id)
//        
//        // Also update the card model for backwards compatibility with main app
//        let container = sharedModelContainer
//        let context = ModelContext(container)
//        
//        let cardID = card.id
//        let fetchDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
//            card.id == cardID
//        })
//        let cards = try context.fetch(fetchDescriptor)
//        
//        if let card = cards.first {
//            let currentDate = Date()
//            card.showAnswer(at: currentDate)
//            try? context.save()
//        }
//        
//        WidgetCenter.shared.reloadAllTimelines()
//        return .result()
//    }
//}
//
//struct ToggleWidgetTextIntent: AppIntent {
//    static var title: LocalizedStringResource = "Toggle Widget Text"
//
//    @Parameter(title: "Card")
//    var card: CardEntity
//    
//    @Parameter(title: "Widget ID")
//    var widgetID: String
//
//    init(card: CardEntity, widgetID: String) {
//        self.card = card
//        self.widgetID = widgetID
//    }
//
//    init() {}
//
//    func perform() async throws -> some IntentResult {
//        // Toggle widget-level text hidden state
//        let currentState = WidgetStateManager.shared.isTextHidden(widgetID: widgetID, cardID: card.id)
//        WidgetStateManager.shared.setTextHidden(!currentState, widgetID: widgetID, cardID: card.id)
//        
//        // No need to update card model - this is widget-specific state
//        WidgetCenter.shared.reloadAllTimelines()
//        return .result()
//    }
//}
//
//
//
//
//
//
//struct SkipCardIntent: AppIntent {
//    static var title: LocalizedStringResource = "Skip Card"
//    
//    @Parameter(title: "Card")
//    var card: CardEntity
//    
//    init(card: CardEntity) {
//        self.card = card
//    }
//    
//    init() {}
//    
//    func perform() async throws -> some IntentResult {
//        let container = sharedModelContainer
//        let context = ModelContext(container)
//        let cardID = card.id
//        let fetchDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
//            card.id == cardID
//        })
//        let cards = try context.fetch(fetchDescriptor)
//        
//        if let cardModel = cards.first {
//            let currentDate = Date()
//            cardModel.skip(at: currentDate)
//            try? context.save()
//            WidgetCenter.shared.reloadAllTimelines()
//        }
//        
//        return .result()
//    }
//}
//
//
//struct NextCardIntent: AppIntent {
//    static var title: LocalizedStringResource = "Next Card"
//    
//    @Parameter(title: "Card")
//    var card: CardEntity
//    
//    init(card: CardEntity) {
//        self.card = card
//    }
//    
//    init() {}
//    
//    func perform() async throws -> some IntentResult {
//        let container = sharedModelContainer
//        let context = ModelContext(container)
//        let cardID = card.id
//        let fetchDescriptor = FetchDescriptor<Card>(predicate: #Predicate { card in
//            card.id == cardID
//        })
//        let cards = try context.fetch(fetchDescriptor)
//        
//        if let cardModel = cards.first {
//            let currentDate = Date()
//            cardModel.next(at: currentDate)
//            try? context.save()
//            WidgetCenter.shared.reloadAllTimelines()
//        }
//        
//        return .result()
//    }
//}
